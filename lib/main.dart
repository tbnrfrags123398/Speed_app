import 'dart:isolate';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math' as math;

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
  double currentSpeed = 0.0; // mph
  int? speedLimit;
  LatLng? currentLatLng;
  double? heading;

  // Trip Stats
  double tripDistanceMeters = 0.0;
  int tripSeconds = 0;
  double maxSpeedMph = 0.0;

  DateTime? _lastSpeedUpdate; // for time-based distance

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

  // ⭐ 0–60 Timer
  bool zeroToSixtyActive = false;
  DateTime? zeroStartTime;
  double zeroToSixtyResult = 0.0;

  // ⭐ Performance Stats
  List<double> _accelHistory = [];
  double _lastHorsepower = 0.0;
  double? _lastSpeedMps;
  DateTime? _lastAccelTime;

  // ⭐ Speed limit fetch throttling
  DateTime? _lastSpeedLimitFetch;
  LatLng? _lastSpeedLimitLatLng;

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

    // ⭐ COMPASS HEADING (works indoors) — throttled
    FlutterCompass.events!.listen((event) {
      final h = event.heading;
      if (h == null) return;

      // Only update if heading changed enough
      if (heading == null || (h - heading!).abs() > 1.0) {
        setState(() {
          heading = h;
        });
      }
    });

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
  // ⭐ 0–60 TIMER LOGIC
  // =============================================================
  void _updateZeroToSixty(double speedMph) {
    if (!zeroToSixtyActive && speedMph > 0.5) {
      zeroToSixtyActive = true;
      zeroStartTime = DateTime.now();
    }

    if (zeroToSixtyActive && speedMph >= 60.0) {
      final endTime = DateTime.now();
      zeroToSixtyResult =
          endTime.difference(zeroStartTime!).inMilliseconds / 1000.0;

      tts.speak(
        "Zero to sixty in ${zeroToSixtyResult.toStringAsFixed(2)} seconds",
      );

      zeroToSixtyActive = false;
      zeroStartTime = null;
    }
  }

  // =============================================================
  // ⭐ FOREGROUND SERVICE LISTENER
  // =============================================================
  void initServiceListener() {
    _receivePort = FlutterForegroundTask.receivePort;

    _receivePort?.listen((data) {
      if (testMode) return;

      final now = DateTime.now();

      if (data["lat"] != null && data["lon"] != null) {
        gpsLastSeen = now;
      }

      final double newSpeed = (data["speed"] ?? 0.0).toDouble();

      // Trip distance based on real time delta
      if (_lastSpeedUpdate != null) {
        final dt = now.difference(_lastSpeedUpdate!).inMilliseconds / 1000.0;
        if (dt > 0 && newSpeed > 0.5) {
          final speedMps = newSpeed * 0.44704; // mph -> m/s
          tripDistanceMeters += speedMps * dt;
          tripSeconds += dt.round();
        }
      }
      _lastSpeedUpdate = now;

      setState(() {
        currentSpeed = newSpeed;
        _updateZeroToSixty(currentSpeed);

        // ⭐ Performance calculations
        final speedMps = currentSpeed * 0.44704; // mph → m/s
        final nowAccel = DateTime.now();

        if (_lastSpeedMps != null && _lastAccelTime != null) {
          final dt =
              nowAccel.difference(_lastAccelTime!).inMilliseconds / 1000.0;
          if (dt > 0) {
            final accel = (speedMps - _lastSpeedMps!) / dt;

            // Store acceleration history
            _accelHistory.add(accel);
            if (_accelHistory.length > 20) {
              _accelHistory.removeAt(0);
            }

            // Auto mass based on mode
            final mass = mode == "bike" ? 100.0 : 1689.0; // kg

            // Horsepower estimate
            _lastHorsepower = (mass * accel * speedMps) / 746.0;
          }
        }

        _lastSpeedMps = speedMps;
        _lastAccelTime = nowAccel;

        if (currentSpeed > maxSpeedMph) {
          maxSpeedMph = currentSpeed;
        }

        if (data["lat"] != null && data["lon"] != null) {
          currentLatLng = LatLng(data["lat"], data["lon"]);
        }

        // heading from service if provided
        heading = data["heading"] ?? heading;
      });

      if (currentLatLng != null && !batterySaver) {
        _maybeFetchSpeedLimit(currentLatLng!);
      }

      handleGpsLostLogic();
      _handleVoiceAlerts();
    });
  }

  // =============================================================
  // ⭐ SPEED LIMIT FETCH THROTTLING
  // =============================================================
  void _maybeFetchSpeedLimit(LatLng pos) {
    final now = DateTime.now();

    // Time throttle: at most once every 5 seconds
    if (_lastSpeedLimitFetch != null &&
        now.difference(_lastSpeedLimitFetch!).inSeconds < 5) {
      return;
    }

    // Distance throttle: only if moved > 20m from last fetch
    if (_lastSpeedLimitLatLng != null) {
      final d = _distanceMeters(_lastSpeedLimitLatLng!, pos);
      if (d < 20.0) return;
    }

    _lastSpeedLimitFetch = now;
    _lastSpeedLimitLatLng = pos;
    fetchSpeedLimit(pos.latitude, pos.longitude);
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const R = 6371000.0; // Earth radius in meters

    final dLat = _degToRad(b.latitude - a.latitude);
    final dLon = _degToRad(b.longitude - a.longitude);
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);

    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) *
            math.sin(dLon / 2) * math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(h));

    return R * c;
  }

  double _degToRad(double deg) => deg * math.pi / 180.0;

  String _asciiAccelGraph() {
    if (_accelHistory.isEmpty) return "";

    final maxVal = _accelHistory.reduce((a, b) => a > b ? a : b);
    if (maxVal <= 0) return "";

    return _accelHistory.map((a) {
      final bars = ((a / maxVal) * 12).clamp(1, 12).round();
      return "|" * bars;
    }).join("\n");
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
  // ⭐ FETCH SPEED LIMIT (OSM / Overpass)
  // =============================================================
  Future<void> fetchSpeedLimit(double lat, double lon) async {
    final query = """
  [out:json];
  (
    way(around:30,$lat,$lon)["maxspeed"];
    way(around:30,$lat,$lon)["maxspeed:type"];
    way(around:30,$lat,$lon)["maxspeed:advisory"];
    relation(around:30,$lat,$lon)["maxspeed"];
    node(around:30,$lat,$lon)["maxspeed"];
  );
  out tags;
  """;

    final url =
        "https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);

      if (data["elements"] == null || data["elements"].isEmpty) return;

      final tags = data["elements"][0]["tags"];
      final raw = tags["maxspeed"] ??
          tags["maxspeed:advisory"] ??
          tags["maxspeed:type"];

      if (raw == null) return;

      int mphLimit;

      if (raw.contains("mph")) {
        mphLimit = int.parse(raw.replaceAll("mph", "").trim());
      } else if (RegExp(r'^\d+$').hasMatch(raw)) {
        mphLimit = (int.parse(raw) * 0.621371).round();
      } else {
        return;
      }

      setState(() => speedLimit = mphLimit);
    } catch (e) {
      print("Speed limit fetch error: $e");
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
  // MODE LABEL
  Positioned(...),

  // PAGEVIEW (must be BEFORE performance panel)
  Positioned.fill(
    child: PageView(
      controller: PageController(initialPage: mode == "bike" ? 0 : 1),
      onPageChanged: (index) {
        setState(() {
          mode = index == 0 ? "bike" : "car";
        });
      },
      children: [
        ScooterHUD(...),
        CarHUD(...),
      ],
    ),
  ),

  // GPS ICON
  Positioned(...),

  // GPS BARS
  Positioned(...),

  // GPS LOST BANNER
  if (gpsLost && !batterySaver) Positioned(...),

  // ⭐ PERFORMANCE PANEL (must be AFTER PageView)
  Positioned(
    bottom: 30,
    left: 20,
    child: GestureDetector(
      onTap: () { ... },
      onDoubleTap: () { ... },
      onLongPress: () { ... },
      child: AnimatedBuilder(...),
    ),
  ),

  // SETTINGS BUTTON
  Positioned(...),
]
