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

    // Request basic location
    await Permission.location.request();

    // Android 14 foreground service location
    await Permission.locationWhenInUse.request();

    // Background location (needed for speed tracking)
    await Permission.locationAlways.request();

    // Check final status
    final granted = await Permission.locationAlways.isGranted ||
                    await Permission.locationWhenInUse.isGranted;

    if (granted) {
      if (mounted) Navigator.pushReplacementNamed(context, "/home");
    } else {
      openAppSettings(); // user must enable manually
    }

    setState(() => _requesting = false);
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
              const Icon(Icons.location_on, size: 100, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                "Speed App Needs Location",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "We use GPS to show your real‑time speed.\n"
                "Please allow location access so the app can work properly.",
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _requesting ? null : requestAllPermissions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                child: _requesting
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text("Allow Location"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
