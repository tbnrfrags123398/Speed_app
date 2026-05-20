import 'package:flutter/material.dart';

class CarHUD extends StatelessWidget {
  final double speed;
  final int? speedLimit;
  final int gpsBars;
  final double? heading;
  final double tripDistanceMeters;
  final int tripSeconds;
  final double maxSpeedMph;
  final bool simpleDisplay;

  final double zeroToSixty;
  final double horsepower;
  final String accelGraph;
  final bool zeroActive;
  final Color panelColor;

  const CarHUD({
    super.key,
    required this.speed,
    required this.speedLimit,
    required this.gpsBars,
    required this.heading,
    required this.tripDistanceMeters,
    required this.tripSeconds,
    required this.maxSpeedMph,
    required this.simpleDisplay,
    required this.zeroToSixty,
    required this.horsepower,
    required this.accelGraph,
    required this.zeroActive,
    required this.panelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ⭐ MAIN SPEED
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                speed.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 120,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
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

        // ⭐ SPEED LIMIT
        Positioned(
          top: 40,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent, width: 1.5),
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

        // ⭐ TRIP + MAX
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

        // ⭐ MODE LABEL (25% height + glow)
        Positioned(
          left: 20,
          top: MediaQuery.of(context).size.height * 0.25,
          child: AnimatedContainer(
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  Colors.redAccent.withOpacity(0.25),
                  Colors.orangeAccent.withOpacity(0.15),
                ],
              ),
              border: Border.all(
                width: 2.5,
                color: Colors.redAccent,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.7),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.orangeAccent.withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.directions_car,
                  size: 26,
                  color: Colors.redAccent,
                ),
                SizedBox(width: 10),
                Text(
                  "CAR MODE",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ⭐ PERFORMANCE PANEL (middle-left + clickable)
        Positioned(
          left: 20,
          top: MediaQuery.of(context).size.height * 0.55,
          child: GestureDetector(
            onTap: () {
              // reset 0–60
            },
            onDoubleTap: () {
              // start 0–60
            },
            onLongPress: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: Colors.black87,
                  title: const Text("Performance Stats",
                      style: TextStyle(color: Colors.white)),
                  content: Text(
                    "0–60: ${zeroToSixty.toStringAsFixed(2)}s\n"
                    "HP: ${horsepower.toStringAsFixed(1)}\n\n"
                    "$accelGraph",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              );
            },
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: zeroActive ? 1.0 : 0.85,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: panelColor.withOpacity(0.9),
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: panelColor.withOpacity(0.7),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "0–60: ${zeroToSixty.toStringAsFixed(2)}s",
                      style: TextStyle(
                        color: zeroActive ? panelColor : Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "HP (Car): ${horsepower.toStringAsFixed(1)}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      accelGraph,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontFamily: "monospace",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
