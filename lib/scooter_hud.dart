import 'package:flutter/material.dart';

class ScooterHUD extends StatelessWidget {
  final double speed;
  final int? speedLimit;
  final int gpsBars;
  final double? heading;
  final double tripDistanceMeters;
  final int tripSeconds;
  final double maxSpeedMph;
  final bool simpleDisplay;

  const ScooterHUD({
    super.key,
    required this.speed,
    required this.speedLimit,
    required this.gpsBars,
    required this.heading,
    required this.tripDistanceMeters,
    required this.tripSeconds,
    required this.maxSpeedMph,
    required this.simpleDisplay,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // MAIN SPEED
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                speed.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 120,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                ),
              ),
              const Text(
                "MPH",
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),

        // SPEED LIMIT
        Positioned(
          top: 40,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.cyanAccent, width: 1.5),
            ),
            child: Text(
              speedLimit == null ? "NO DATA" : "${speedLimit} MPH",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // TRIP + MAX
        Positioned(
          bottom: 40,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "TIME ${tripSeconds ~/ 60}m ${tripSeconds % 60}s",
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              Text(
                "MAX ${maxSpeedMph.toStringAsFixed(0)} mph",
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),

        // ⭐ MODE LABEL (middle-left)
        Positioned(
          left: 20,
          top: MediaQuery.of(context).size.height * 0.40,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  Colors.cyanAccent.withOpacity(0.25),
                  Colors.blueAccent.withOpacity(0.15),
                ],
              ),
              border: Border.all(
                width: 2.5,
                color: Colors.cyanAccent,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.7),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.pedal_bike,
                  size: 26,
                  color: Colors.cyanAccent,
                ),
                SizedBox(width: 10),
                Text(
                  "BIKE MODE",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.cyanAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
