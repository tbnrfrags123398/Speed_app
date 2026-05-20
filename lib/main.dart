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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.locationWhenInUse.status;

    if (status.isGranted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    } else {
      setState(() => checking = false);
    }
  }

  Future<void> _requestPermission() async {
    final result = await Permission.locationWhenInUse.request();

    if (result.isGranted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (checking) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
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
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "This app needs GPS to work.",
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _requestPermission,
              child: const Text("Allow GPS"),
            ),
          ],
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
  DateTime? tripStartTime;

  // Live Performance Data
  double speed = 0;
  double accel = 0;
  double horsepower = 0;

  // Dyno History
  List<double> hpHistory = [];

  final PageController _controller = PageController();

  @override
  void initState() {
    super.initState();
    _initForegroundService();
  }

  Future<void> _initForegroundService() async {
    _receivePort = await FlutterForegroundTask.receivePort;

    if (_receivePort != null) {
      _receivePort!.listen((data) {
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
      speed = data["speed"] ?? 0.0;
      gpsHeading = data["heading"] ?? 0.0;

      double lat = data["lat"] ?? 0.0;
      double lon = data["lon"] ?? 0.0;

      // GPS Bars (based on accuracy)
      gpsBars = data["gpsBars"] ?? 1;

      // Trip Start
      tripStartTime ??= DateTime.now();

      // Trip Timer
      tripSeconds = DateTime.now().difference(tripStartTime!).inSeconds;

      // Trip Distance
      if (lastLat != null && lastLon != null) {
        tripDistanceMeters += _distanceBetween(lastLat!, lastLon!, lat, lon);
      }

      lastLat = lat;
      lastLon = lon;

      // Max Speed
      if (speed > maxSpeedMph) {
        maxSpeedMph = speed;
      }

      // Accel + HP
      accel = (speed / 60).clamp(0, 1);
      horsepower = (speed * accel * 3).clamp(0, 250);

      hpHistory.add(horsepower);
      if (hpHistory.length > 200) hpHistory.removeAt(0);
    });
  }

  double _distanceBetween(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000;
    double dLat = (lat2 - lat1) * 0.0174533;
    double dLon = (lon2 - lon1) * 0.0174533;

    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(lat1 * 0.0174533) *
            cos(lat2 * 0.0174533) *
            (sin(dLon / 2) * sin(dLon / 2));

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  void goToPerformance() {
    _controller.animateToPage(
      2,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void goToCarHUD() {
    _controller.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView(
        controller: _controller,
        physics: const BouncingScrollPhysics(),
        children: [
          ScooterHUD(
            speed: speed,
            accel: accel,
            horsepower: horsepower,
            gpsBars: gpsBars,
            headingDegrees: gpsHeading,
            tripDistanceMeters: tripDistanceMeters,
            tripSeconds: tripSeconds,
            maxSpeedMph: maxSpeedMph,
          ),
          CarHUD(
            speed: speed,
            accel: accel,
            horsepower: horsepower,
            onSwipeRight: goToPerformance,
          ),
          PerformanceScreen(
            speed: speed,
            accel: accel,
            horsepower: horsepower,
            hpHistory: hpHistory,
            onSwipeLeft: goToCarHUD,
          ),
        ],
      ),
    );
  }
}

