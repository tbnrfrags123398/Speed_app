import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  bool _requesting = false;

  Future<void> requestAllPermissions() async {
    setState(() => _requesting = true);

    await Permission.location.request();
    await Permission.locationWhenInUse.request();
    await Permission.locationAlways.request();

    final granted = await Permission.locationAlways.isGranted ||
        await Permission.locationWhenInUse.isGranted;

    if (granted) {
      if (mounted) Navigator.pushReplacementNamed(context, "/home");
    } else {
      openAppSettings();
    }

    setState(() => _requesting = false);
  }

  void _continueWithoutGps() {
    Navigator.pushReplacementNamed(context, "/home");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔥 Neon glowing circle
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0066FF), // neon blue
                      Color(0xFFFF0033), // neon red
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.7),
                      blurRadius: 30,
                      spreadRadius: 3,
                    ),
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.7),
                      blurRadius: 30,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on,
                  size: 90,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                "Speed HUD Needs GPS",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              const Text(
                "GPS is required to show your real‑time speed,\n"
                "speed limits, and trip stats.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 50),

              // 🔵 Neon Allow Button
              ElevatedButton(
                onPressed: _requesting ? null : requestAllPermissions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                  shadowColor: Colors.blueAccent.withOpacity(0.8),
                  elevation: 12,
                ),
                child: _requesting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "ALLOW GPS",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
              ),

              const SizedBox(height: 20),

              // ⚪ Continue without GPS
              TextButton(
                onPressed: _continueWithoutGps,
                child: const Text(
                  "Continue without GPS",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 18,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
