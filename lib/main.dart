import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'car_hud.dart';
import 'performance_screen.dart';
import 'scooter_hud.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⭐ LOCK APP TO PORTRAIT ONLY
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
  final PageController _controller = PageController(initialPage: 1);

  // ⭐ LIVE PERFORMANCE DATA
  double speed = 0;
  double accel = 0;
  double horsepower = 0;

  // ⭐ DYNO HISTORY (for performance screen)
  List<double> hpHistory = [];

  Timer? updateTimer;

  @override
  void initState() {
    super.initState();

    // ⭐ FAST UPDATE LOOP (0.1s)
    updateTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        // Simulated values — replace with real GPS/OBD later
        speed += 0.2;
        accel = (speed / 60).clamp(0, 1);
        horsepower = (speed * accel * 3).clamp(0, 250);

        // ⭐ Update dyno history
        hpHistory.add(horsepower);
        if (hpHistory.length > 120) {
          hpHistory.removeAt(0);
        }
      });
    });
  }

  @override
  void dispose() {
    updateTimer?.cancel();
    super.dispose();
  }

  // ⭐ SWIPE HANDLERS
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
          // ⭐ PAGE 0 — SCOOTER HUD
          ScooterHUD(),

          // ⭐ PAGE 1 — CAR HUD
          CarHUD(
            speed: speed,
            accel: accel,
            horsepower: horsepower,
            onSwipeRight: goToPerformance,
          ),

          // ⭐ PAGE 2 — PERFORMANCE SCREEN
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
// ⭐ END OF MAINPAGE CLASS
// No extra code needed here — everything is wired above.

// The file ends here cleanly.
// Make sure CarHUD, ScooterHUD, and PerformanceScreen
// are in the same folder or adjust imports accordingly.
