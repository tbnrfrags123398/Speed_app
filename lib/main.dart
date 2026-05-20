import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'car_hud.dart';
import 'performance_screen.dart';
import 'scooter_hud.dart';
import 'gps_service.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(GpsTaskHandler());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: Colors.blueAccent,
        secondary: Colors.blueAccent,
      ),
      fontFamily: 'Roboto',
      useMaterial3: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speed App',
      debugShowCheckedModeBanner: false,
      theme: _buildDarkTheme(),
      home: const PermissionGate(),
    );
  }
}

class PermissionGate extends StatefulWidget {
  const PermissionGate({super.key});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  bool checking = true;
  bool deniedOnce = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.locationWhenInUse.status;

    if (status.isGranted) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    } else {
      setState(() {
        checking = false;
        deniedOnce = status.isDenied || status.isPermanentlyDenied;
      });
    }
  }

  Future<void> _requestPermission() async {
    final result = await Permission.locationWhenInUse.request();

    if (result.isGranted) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    } else {
      setState(() {
        deniedOnce = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (checking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off, size: 80, color: Colors.redAccent),
              const SizedBox(height: 20),
              const Text(
                "GPS REQUIRED",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                deniedOnce
                    ? "You denied GPS before. Enable it so the speedometer can work."
                    : "This app needs GPS to show your speed and trip data.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _requestPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  "Allow GPS",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  ReceivePort? _receivePort;

  // GPS + Trip Data
  double gpsHeading = 0.0;
  int gpsBars = 0;

  double tripDistanceMeters = 0.0;
  int tripSeconds = 0;
  double maxSpeedMph = 0.0;

  double? lastLat;
  double? lastLon;

  // Live Performance Data
  double speed = 0;
  double accel = 0;
  double horsepower = 0;

  // Instant startup speed
  double? lastKnownSpeed;

  // Dyno History
  final List<double> hpHistory = [];

  // Trip auto‑pause
  bool tripPaused = true;
  double _prevSpeed = 0.0;

  // Real 0–30 / 0–60 timers (ms)
  int zeroTo30Ms = 0;
  int zeroTo60Ms = 0;
  DateTime? _launchStart;
  bool _hit30 = false;
  bool _hit60 = false;

  final PageController _controller = PageController();
  StreamSubscription? _portSub;

  @override
  void initState() {
    super.initState();
    _initForegroundService();
  }

  @override
  void dispose() {
    _portSub?.cancel();
    _receivePort?.close();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initForegroundService() async {
    _receivePort = await FlutterForegroundTask.receivePort;

    if (_receivePort != null) {
      _portSub = _receivePort!.listen((data) {
        if (data is Map) {
          _updateFromGps(data);
        }
      });
    }

    await FlutterForegroundTask.startService(
      notificationTitle: "Speed App Running",
      notificationText: "Collecting GPS data...",
      callback: startCallback,
    );
  }

  void _updateFromGps(Map data) {
    setState(() {
      final double newSpeed = (data["speed"] ?? 0.0).toDouble();
      speed = newSpeed;
      lastKnownSpeed = speed;

      gpsHeading = (data["heading"] ?? 0.0).toDouble();

      final double lat = (data["lat"] ?? 0.0).toDouble();
      final double lon = (data["lon"] ?? 0.0).toDouble();

      gpsBars = (data["gpsBars"] ?? 1).toInt().clamp(0, 5);

      // Auto‑pause / resume trip
      final bool moving = speed >= 1.0;
      tripPaused = !moving;

      // Trip time: count only when moving (1 tick ≈ 1s)
      if (!tripPaused) {
        tripSeconds++;
      }

      // Trip distance: only when moving
      if (!tripPaused && lastLat != null && lastLon != null) {
        tripDistanceMeters += _distanceBetween(lastLat!, lastLon!, lat, lon);
      }

      lastLat = lat;
      lastLon = lon;

      // Max speed
      if (speed > maxSpeedMph) {
        maxSpeedMph = speed;
      }

      // Accel + HP
      accel = (speed / 60).clamp(0, 1);
      horsepower = (speed * accel * 3).clamp(0, 250);

      hpHistory.add(horsepower);
      if (hpHistory.length > 300) hpHistory.removeAt(0);

      // REAL 0–30 / 0–60 timers
      _updateLaunchTimers();

      _prevSpeed = speed;
    });
  }

  void _updateLaunchTimers() {
    // Start launch when crossing from basically stopped to moving
    if (_launchStart == null && _prevSpeed < 1.0 && speed >= 1.0) {
      _launchStart = DateTime.now();
      _hit30 = false;
      _hit60 = false;
      zeroTo30Ms = 0;
      zeroTo60Ms = 0;
    }

    if (_launchStart != null) {
      final int elapsedMs =
          DateTime.now().difference(_launchStart!).inMilliseconds;

      if (!_hit30 && speed >= 30.0) {
        _hit30 = true;
        zeroTo30Ms = elapsedMs;
      }

      if (!_hit60 && speed >= 60.0) {
        _hit60 = true;
        zeroTo60Ms = elapsedMs;
      }

      // If we slow back down a lot, reset launch
      if (speed < 3.0 && elapsedMs > 8000 && !_hit60) {
        _launchStart = null;
      }
    }
  }

  double _distanceBetween(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final double dLat = (lat2 - lat1) * (pi / 180.0);
    final double dLon = (lon2 - lon1) * (pi / 180.0);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) *
            cos(lat2 * (pi / 180.0)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  void goToPerformance() {
    _controller.animateToPage(
      2,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void goToCarHUD() {
    _controller.animateToPage(
      1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double displaySpeed = lastKnownSpeed ?? speed;

    return Scaffold(
      body: PageView(
        controller: _controller,
        physics: const BouncingScrollPhysics(),
        children: [
          ScooterHUD(
            speed: displaySpeed,
            accel: accel,
            horsepower: horsepower,
            gpsBars: gpsBars,
            headingDegrees: gpsHeading,
            tripDistanceMeters: tripDistanceMeters,
            tripSeconds: tripSeconds,
            maxSpeedMph: maxSpeedMph,
          ),
          CarHUD(
            speed: displaySpeed,
            accel: accel,
            horsepower: horsepower,
            onSwipeRight: goToPerformance,
          ),
          PerformanceScreen(
            speed: displaySpeed,
            accel: accel,
            horsepower: horsepower,
            hpHistory: hpHistory,
            zeroTo30Ms: zeroTo30Ms,
            zeroTo60Ms: zeroTo60Ms,
            onSwipeLeft: goToCarHUD,
          ),
        ],
      ),
    );
  }
}
