import 'package:flutter/material.dart';

class ScooterHUD extends StatelessWidget {
  final double speed;
  final double accel;
  final double horsepower;

  final int gpsBars;
  final double headingDegrees;
  final double tripDistanceMeters;
  final int tripSeconds;
  final double maxSpeedMph;

  const ScooterHUD({
    super.key,
    required this.speed,
    required this.accel,
    required this.horsepower,
    required this.gpsBars,
    required this.headingDegrees,
    required this.tripDistanceMeters,
    required this.tripSeconds,
    required this.maxSpeedMph,
  });

  String _headingText() {
    final dirs = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"];
    int index = ((headingDegrees % 360) / 45).round() % 8;
    return dirs[index];
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return "${m}m ${s}s";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // TOP BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // GPS BARS
                  Row(
                    children: List.generate(
                      5,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 8,
                        height: 12 + (i * 3),
                        decoration: BoxDecoration(
                          color: i < gpsBars
                              ? Colors.greenAccent
                              : Colors.white12,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),

                  // HEADING
                  Text(
                    _headingText(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // SPEED
            Text(
              speed.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 120,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "MPH",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 28,
                letterSpacing: 3,
              ),
            ),

            const SizedBox(height: 40),

            // ACCEL BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: LinearProgressIndicator(
                value: accel,
                minHeight: 10,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.blueAccent,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // HORSEPOWER
            Text(
              "${horsepower.toStringAsFixed(0)} HP",
              style: const TextStyle(
                color: Colors.blueAccent,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Spacer(),

            // TRIP DATA
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                children: [
                  Text(
                    "Trip: ${(tripDistanceMeters / 1609.34).toStringAsFixed(2)} mi",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Time: ${_formatTime(tripSeconds)}",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Max: ${maxSpeedMph.toStringAsFixed(1)} mph",
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

