import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import 'gps_service.dart';
import 'scooter_hud.dart';
import 'car_hud.dart';
import 'settings_screen.dart';
import 'permission_page.dart';


// =============================================================
// ⭐ FOREGROUND SERVICE ENTRY POINT
// =============================================================
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(GpsTaskHandler());
}


// =============================================================
// ⭐ MAIN APP INITIALIZATION
// =============================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'speed_app_channel',
      channelName: 'Speed App Background Service',
      channelDescription: 'Keeps GPS and speed limit active',
      channelImportance: NotificationChannelImportance.HIGH,
      priority: NotificationPriority.HIGH,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: const ForegroundTaskOptions(
      interval: 1000,
      autoRunOnBoot: false,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );

  runApp(const SpeedApp());
}


// =============================================================
// ⭐ ROOT APP WIDGET
// =============================================================
class SpeedApp extends StatelessWidget {
  const SpeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/permissions",
      routes: {
        "/permissions": (context) => const PermissionPage(),
        "/home": (context) => const HomeWrapper(),
      },
    );
  }
}


// =============================================================
// ⭐ HOME WRAPPER — STARTS FOREGROUND SERVICE
// =============================================================
class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  bool started = false;

  @override
  void initState() {
    super.initState();
    startServiceSafely();
  }

  Future<void> startServiceSafely() async {
    if (await Permission.location.isGranted &&
        await Permission.locationWhenInUse.isGranted) {
      await FlutterForegroundTask.startService(
        notificationTitle: "Speed HUD Running",
        notificationText: "GPS Active",
        callback: startCallback,
      );
      setState(() => started = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!started) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return const SpeedHome();
  }
}


// =============================================================
// ⭐ MAIN HOME SCREEN (HUD + GPS LOGIC)
// =============================================================
class SpeedHome extends StatefulWidget {
  const SpeedHome({super.key});

  @override
  State<SpeedHome> createState() => _SpeedHomeState();
}

class _SpeedHomeState extends State<SpeedHome>
    with WidgetsBindingObserver, TickerProviderStateMixin {

  // TTS
  final FlutterTts tts = FlutterTts();

  // GPS + Speed
  double currentSpeed = 0.0;
  int? speedLimit;
  LatLng? currentLatLng;
  double? heading;

  // Trip Stats
  double tripDistanceMeters = 0.0;
  int tripSeconds = 0;
  double maxSpeedMph = 0.0;

  // Modes
  bool batterySaver = false;
  bool testMode = false;
  String mode = "bike";

  // Foreground service
  ReceivePort? _receivePort;

  // =============================================================
  // ⭐ GPS LOST SYSTEM VARIABLES
  // =============================================================
  bool gpsLost = false;
  DateTime? gpsLastSeen;
  bool gpsLostAnnounced = false;
  bool gpsRestoredAnnounced = false;

  // Fade animation (fade-in once → solid → fade-out)
  late AnimationController gpsFadeController;
  late Animation<double> gpsFade;

  // =============================================================
  // ⭐ GPS ICON PULSE + SCANNING BARS
  // =============================================================
  late AnimationController gpsPulseController;
  late Animation<double> gpsPulse;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Pulse animation for GPS icon
    gpsPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    gpsPulse = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: gpsPulseController, curve: Curves.easeInOut),
    );

    // Fade animation for GPS LOST banner
    gpsFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    gpsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: gpsFadeController, curve: Curves.easeInOut),
    );

    initServiceListener();
  }


  @override
  void dispose() {
    gpsPulseController.dispose();
    gpsFadeController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    FlutterForegroundTask.stopService();
    super.dispose();
  }


  // =============================================================
  // ⭐ GPS SIGNAL BARS (ALWAYS 4 WHEN FIXED)
  // =============================================================
  int get gpsBars {
    if (currentLatLng == null) return 0;
    return 4;
  }


  // =============================================================
  // ⭐ FOREGROUND SERVICE LISTENER
  // =============================================================
  void initServiceListener() {
    _receivePort = FlutterForegroundTask.receivePort;

    _receivePort?.listen((data) {
      if (testMode) return;

      // Update GPS timestamp
      if (data["lat"] != null && data["lon"] != null) {
        gpsLastSeen = DateTime.now();
      }

      // Update speed
      setState(() {
        currentSpeed = data["speed"] ?? 0.0;

        if (currentSpeed > maxSpeedMph) {
          maxSpeedMph = currentSpeed;
        }

        if (data["lat"] != null && data["lon"] != null) {
          currentLatLng = LatLng(data["lat"], data["lon"]);
        }

        heading = data["heading"];
      });

      // Trip stats
      if (currentSpeed > 1.0) {
        tripSeconds += 1;
        tripDistanceMeters += (currentSpeed / 2.23694);
      }

      // Speed limit fetch
      if (currentLatLng != null) {
        fetchSpeedLimit(currentLatLng!.latitude, currentLatLng!.longitude);
      }

      // GPS LOST detection
      handleGpsLostLogic();
    });
  }


  // =============================================================
  // ⭐ GPS LOST LOGIC (2-second delay)
  // =============================================================
  void handleGpsLostLogic() {
    if (batterySaver) {
      gpsLost = false;
      gpsFadeController.reset();
      return;
    }

    final now = DateTime.now();

    // If GPS hasn't been seen for 2 seconds → LOST
    if (gpsLastSeen == null ||
        now.difference(gpsLastSeen!).inMilliseconds > 2000) {

      if (!gpsLost) {
        gpsLost = true;
        gpsLostAnnounced = false;
        gpsRestoredAnnounced = false;

        // Fade in once
        gpsFadeController.forward(from: 0.0);
      }

      if (!gpsLostAnnounced) {
        gpsLostAnnounced = true;
        tts.speak("GPS signal lost");
      }

    } else {
      // GPS restored
      if (gpsLost) {
        gpsLost = false;

        if (!gpsRestoredAnnounced) {
          gpsRestoredAnnounced = true;
          tts.speak("GPS signal restored");
        }

        // Fade out smoothly
        gpsFadeController.reverse();
      }
    }
  }


  // =============================================================
  // ⭐ FETCH SPEED LIMIT FROM OSM
  // =============================================================
  Future<void> fetchSpeedLimit(double lat, double lon) async {
    final url =
        "https://overpass-api.de/api/interpreter?data=[out:json];way(around:20,$lat,$lon)[\"maxspeed\"];out;";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["elements"] != null && data["elements"].isNotEmpty) {
          final tags = data["elements"][0]["tags"];
          final raw = tags["maxspeed"];

          if (raw != null) {
            int mphLimit;

            if (raw.contains("mph")) {
              mphLimit = int.parse(raw.replaceAll("mph", "").trim());
            } else {
              mphLimit = (int.parse(raw) * 0.621371).round();
            }

            setState(() => speedLimit = mphLimit);
          }
        }
      }
    } catch (e) {
      print("OSM speed limit error: $e");
    }
  }
  // =============================================================
  // ⭐ BUILD UI
  // =============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          // =============================================================
          // ⭐ MAIN HUD (BIKE OR CAR)
          // =============================================================
          Positioned.fill(
            child: mode == "bike"
                ? ScooterHUD(
                    speed: currentSpeed,
                    speedLimit: speedLimit,
                    gpsBars: gpsBars,
                    heading: heading,
                    tripDistanceMeters: tripDistanceMeters,
                    tripSeconds: tripSeconds,
                    maxSpeedMph: maxSpeedMph,
                  )
                : CarHUD(
                    speed: currentSpeed,
                    speedLimit: speedLimit,
                    gpsBars: gpsBars,
                    heading: heading,
                    tripDistanceMeters: tripDistanceMeters,
                    tripSeconds: tripSeconds,
                    maxSpeedMph: maxSpeedMph,
                  ),
          ),

          // =============================================================
          // ⭐ GPS PULSING ICON (TOP RIGHT)
          // =============================================================
          Positioned(
            top: 40,
            right: 20,
            child: AnimatedBuilder(
              animation: gpsPulseController,
              builder: (context, child) {
                return Opacity(
                  opacity: gpsPulse.value,
                  child: Icon(
                    Icons.gps_fixed,
                    size: 32,
                    color: gpsLost ? Colors.red : Colors.greenAccent,
                  ),
                );
              },
            ),
          ),

          // =============================================================
          // ⭐ ANIMATED GPS SCANNING BARS (TOP RIGHT UNDER ICON)
          // =============================================================
          Positioned(
            top: 80,
            right: 20,
            child: Row(
              children: List.generate(4, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: (i + 1) * 10,
                  decoration: BoxDecoration(
                    color: gpsLost ? Colors.red : Colors.greenAccent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),

          // =============================================================
          // ⭐ CENTER NEON GPS LOST BANNER (FADE IN ONCE → SOLID → FADE OUT)
          // =============================================================
          if (gpsLost && !batterySaver)
            Center(
              child: FadeTransition(
                opacity: gpsFade,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.8),
                        blurRadius: 25,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Text(
                    "⚠ NO GPS — SPEED INACCURATE",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),

          // =============================================================
          // ⭐ SETTINGS BUTTON (TOP LEFT)
          // =============================================================
          Positioned(
            top: 40,
            left: 20,
            child: GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      batterySaver: batterySaver,
                      mode: mode,
                      testMode: testMode,
                    ),
                  ),
                );

                if (result != null) {
                  setState(() {
                    batterySaver = result["batterySaver"];
                    mode = result["mode"];
                    testMode = result["testMode"];
                  });
                }
              },
              child: const Icon(
                Icons.settings,
                size: 34,
                color: Colors.white,
              ),
            ),
          ),

        ],
      ),
    );
  }
}

