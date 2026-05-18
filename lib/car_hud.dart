import 'package:flutter/material.dart';

class CarHUD extends StatelessWidget {
  final double speed;
  final int? speedLimit;
  final int gpsBars;
  final double? heading;
  final double tripDistanceMeters;
  final int tripSeconds;
  final double maxSpeedMph;

  const CarHUD({
    super.key,
    required this.speed,
    required this.speedLimit,
    required this.gpsBars,
    required this.heading,
    required this.tripDistanceMeters,
    required this.tripSeconds,
    required this.maxSpeedMph,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF000000),
            Color(0xFF0A0000),
            Color(0xFF000000),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // ⭐ Neon Speed Number (Red)
          Center(
            child: Text(
              speed.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 150,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
                shadows: [
                  Shadow(
                    color: Colors.redAccent.withOpacity(0.9),
                    blurRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          // ⭐ Speed Limit (bottom center)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              speedLimit != null ? "LIMIT ${speedLimit} MPH" : "NO LIMIT",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                color: Colors.orangeAccent,
                shadows: [
                  Shadow(
                    color: Colors.orangeAccent.withOpacity(0.8),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          // ⭐ GPS Bars (top right)
          Positioned(
            top: 40,
            right: 30,
            child: Row(
              children: List.generate(4, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: (i + 1) * 12,
                  decoration: BoxDecoration(
                    color: gpsBars > i ? Colors.redAccent : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: gpsBars > i
                            ? Colors.redAccent.withOpacity(0.7)
                            : Colors.grey.withOpacity(0.7),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),

          // ⭐ Trip Stats (bottom left)
          Positioned(
            bottom: 40,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _stat("DIST", "${(tripDistanceMeters / 1609).toStringAsFixed(2)} mi"),
                _stat("TIME", "${tripSeconds ~/ 60}m ${(tripSeconds % 60)}s"),
                _stat("MAX", "${maxSpeedMph.toStringAsFixed(0)} mph"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        "$label  $value",
        style: TextStyle(
          color: Colors.white70,
          fontSize: 18,
          shadows: [
            Shadow(
              color: Colors.redAccent.withOpacity(0.4),
              blurRadius: 10,
            ),
          ],
        ),
      ),
    );
  }
}

