import 'dart:isolate';
import 'dart:async';
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

  // Modes / Settings
  bool batterySaver = false;
  bool testMode = false;
  String mode = "bike"; // controlled ONLY by swipe
  String mapStyle = "dark";
  bool voiceAlerts = true;
  bool simpleDisplay = false;

  // Foreground service
  ReceivePort? _receivePort;

  // GPS LOST SYSTEM
  bool gpsLost = false;
  DateTime? gpsLastSeen;
  bool gpsLostAnnounced = false;
  bool gpsRestoredAnnounced = false;

  // Fade animation (GPS LOST banner)
  late AnimationController gpsFadeController;
  late Animation<double> gpsFade;

  // GPS ICON PULSE
  late AnimationController gpsPulseController;
  late Animation<double> gpsPulse;

  // Test mode simulation
  Timer? _testTimer;
  int _fakeSpeed = 0;
  int _fakeDir = 1;
  int _fakeLimitIndex = 0;
  final List<int> _fakeLimits = [25, 35, 45, 55];

  int? _lastAnnouncedSpeedLimit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    gpsPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    gpsPulse = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: gpsPulseController, curve: Curves.easeInOut),
    );

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
    _testTimer?.cancel();
    gpsPulseController.dispose();
    gpsFadeController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    FlutterForegroundTask.stopService();
    super.dispose();
  }

  // =============================================================
  // ⭐ GPS SIGNAL BARS
  // =============================================================
  int get gpsBars {
    if (currentLatLng == null && !testMode) return 0;
    return 4;
  }

  // =============================================================
  // ⭐ FOREGROUND SERVICE LISTENER
  // =============================================================
  void initServiceListener() {
    _receivePort = FlutterForegroundTask.receivePort;

    _receivePort?.listen((data) {
      if (testMode) return;

      if (data["lat"] != null && data["lon"] != null) {
        gpsLastSeen = DateTime.now();
      }

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

      if (currentSpeed > 1.0) {
        tripSeconds += 1;
        tripDistanceMeters += (currentSpeed / 2.23694);
      }

      if (currentLatLng != null && !batterySaver) {
        fetchSpeedLimit(currentLatLng!.latitude, currentLatLng!.longitude);
      }

      handleGpsLostLogic();
      _handleVoiceAlerts();
    });
  }

  // =============================================================
  // ⭐ TEST MODE SIMULATION
  // =============================================================
  void _startTestMode() {
    _testTimer?.cancel();
    gpsLost = false;
    gpsLastSeen = DateTime.now();
    _fakeSpeed = 0;
    _fakeDir = 1;
    _fakeLimitIndex = 0;
    speedLimit = _fakeLimits[_fakeLimitIndex];

    _testTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_fakeDir == 1) {
          _fakeSpeed += 5;
          if (_fakeSpeed >= 45) {
            _fakeSpeed = 45;
            _fakeDir = -1;
          }
        } else {
          _fakeSpeed -= 5;
          if (_fakeSpeed <= 0) {
            _fakeSpeed = 0;
            _fakeDir = 1;
            _fakeLimitIndex = (_fakeLimitIndex + 1) % _fakeLimits.length;
            speedLimit = _fakeLimits[_fakeLimitIndex];
          }
        }

        currentSpeed = _fakeSpeed.toDouble();

        if (currentSpeed > maxSpeedMph) {
          maxSpeedMph = currentSpeed;
        }

        gpsLost = false;
        gpsLastSeen = DateTime.now();

        if (currentSpeed > 1.0) {
          tripSeconds += 1;
          tripDistanceMeters += (currentSpeed / 2.23694);
        }
      });

      handleGpsLostLogic();
      _handleVoiceAlerts();
    });
  }

  void _stopTestMode() {
    _testTimer?.cancel();
    _testTimer = null;
  }

  // =============================================================
  // ⭐ GPS LOST LOGIC
  // =============================================================
  void handleGpsLostLogic() {
    if (batterySaver) {
      gpsLost = false;
      gpsFadeController.reset();
      return;
    }

    final now = DateTime.now();

    if (gpsLastSeen == null ||
        now.difference(gpsLastSeen!).inMilliseconds > 2000) {
      if (!gpsLost) {
        gpsLost = true;
        gpsLostAnnounced = false;
        gpsRestoredAnnounced = false;

        gpsFadeController.forward(from: 0.0);
      }

      if (!gpsLostAnnounced && voiceAlerts) {
        gpsLostAnnounced = true;
        tts.speak("GPS signal lost");
      }
    } else {
      if (gpsLost) {
        gpsLost = false;

        if (!gpsRestoredAnnounced && voiceAlerts) {
          gpsRestoredAnnounced = true;
          tts.speak("GPS signal restored");
        }

        gpsFadeController.reverse();
      }
    }
  }

  // =============================================================
  // ⭐ VOICE ALERTS
  // =============================================================
  void _handleVoiceAlerts() {
    if (!voiceAlerts || batterySaver) return;
    if (speedLimit == null) return;

    if (_lastAnnouncedSpeedLimit != speedLimit) {
      _lastAnnouncedSpeedLimit = speedLimit;
      tts.speak("Speed limit ${speedLimit} miles per hour");
    }

    if (currentSpeed > (speedLimit! + 5)) {
      tts.speak("Slow down");
    }
  }

  // =============================================================
  // ⭐ FETCH SPEED LIMIT
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
  // ⭐ APPLY SETTINGS (FIXED — NO MODE)
  // =============================================================
  void _applySettings(Map result) {
    setState(() {
      testMode = result["testMode"] ?? testMode;
      batterySaver = result["batterySaver"] ?? batterySaver;
      mapStyle = result["mapStyle"] ?? mapStyle;
      voiceAlerts = result["voiceAlerts"] ?? voiceAlerts;
   simpleDisplay = result["simpleDisplay"] ?? simpleDisplay;
 });

    if (testMode) {
      _startTestMode();
    } else {
      _stopTestMode();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          // ⭐ ULTRA FUTURISTIC MODE LABEL (CYBERPUNK)
          Positioned(
            top: 18,
            left: 0,
            right: 0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, anim) {
                return ScaleTransition(
                  scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                  child: child,
                );
              },
              child: Container(
                key: ValueKey(mode),
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: mode == "bike"
                        ? [
                            Colors.cyanAccent.withOpacity(0.25),
                            Colors.blueAccent.withOpacity(0.15),
                          ]
                        : [
                            Colors.redAccent.withOpacity(0.25),
                            Colors.orangeAccent.withOpacity(0.15),
                          ],
                  ),
                  border: Border.all(
                    width: 2.5,
                    color: mode == "bike" ? Colors.cyanAccent : Colors.redAccent,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: mode == "bike"
                          ? Colors.cyanAccent.withOpacity(0.7)
                          : Colors.redAccent.withOpacity(0.7),
                      blurRadius: 25,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: mode == "bike"
                          ? Colors.blueAccent.withOpacity(0.4)
                          : Colors.orangeAccent.withOpacity(0.4),
                      blurRadius: 40,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      mode == "bike" ? Icons.pedal_bike : Icons.directions_car,
                      size: 26,
                      color: mode == "bike" ? Colors.cyanAccent : Colors.redAccent,
                      shadows: [
                        Shadow(
                          color: mode == "bike"
                              ? Colors.cyanAccent.withOpacity(0.9)
                              : Colors.redAccent.withOpacity(0.9),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Text(
                      mode == "bike" ? "BIKE MODE" : "CAR MODE",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: mode == "bike" ? Colors.cyanAccent : Colors.redAccent,
                        shadows: [
                          Shadow(
                            color: mode == "bike"
                                ? Colors.cyanAccent.withOpacity(0.9)
                                : Colors.redAccent.withOpacity(0.9),
                            blurRadius: 25,
                          ),
                          Shadow(
                            color: mode == "bike"
                                ? Colors.blueAccent.withOpacity(0.5)
                                : Colors.orangeAccent.withOpacity(0.5),
                            blurRadius: 40,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ⭐ SWIPE LEFT/RIGHT TO SWITCH MODES
          Positioned.fill(
            child: PageView(
              controller: PageController(initialPage: mode == "bike" ? 0 : 1),
              onPageChanged: (index) {
                setState(() {
                  mode = index == 0 ? "bike" : "car";
                });
              },

              children: [
                ScooterHUD(
                  speed: currentSpeed,
                  speedLimit: speedLimit,
                  gpsBars: gpsBars,
                  heading: heading,
                  tripDistanceMeters: tripDistanceMeters,
                  tripSeconds: tripSeconds,
                  maxSpeedMph: maxSpeedMph,
                  simpleDisplay: simpleDisplay,
                ),

                CarHUD(
                  speed: currentSpeed,
                  speedLimit: speedLimit,
                  gpsBars: gpsBars,
                  heading: heading,
                  tripDistanceMeters: tripDistanceMeters,
                  tripSeconds: tripSeconds,
                  maxSpeedMph: maxSpeedMph,
                  simpleDisplay: simpleDisplay,
                ),
              ],
            ),
          ),

          // ⭐ GPS PULSING ICON
          Positioned(
            top: 40,
            right: 20,
            child: AnimatedBuilder(
              animation: gpsPulseController,
              builder: (context, child) {
                final opacity = batterySaver ? 0.4 : gpsPulse.value;
                return Opacity(
                  opacity: opacity,
                  child: Icon(
                    Icons.gps_fixed,
                    size: 32,
                    color: gpsLost ? Colors.red : Colors.greenAccent,
                  ),
                );
              },
            ),
          ),

          // ⭐ GPS SCANNING BARS
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

          // ⭐ GPS LOST BANNER
          if (gpsLost && !batterySaver)
            Center(
              child: FadeTransition(
                opacity: gpsFade,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
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

          // ⭐ SETTINGS BUTTON
          Positioned(
            top: 40,
            left: 20,
            child: GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      testMode: testMode,
                      batterySaver: batterySaver,
                      mapStyle: mapStyle,
                      voiceAlerts: voiceAlerts,
                      simpleDisplay: simpleDisplay, // ⭐ REQUIRED
                    ),
                  ),
                );

                if (result != null) {
                  _applySettings(result);
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
