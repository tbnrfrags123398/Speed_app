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
    final bool isSpeeding =
        speedLimit != null && speed > (speedLimit! + 5);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF050000),
            Color(0xFF000000),
            Color(0xFF180000),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // ⭐ Background glow
          Positioned.fill(
            child: Opacity(
              opacity: 0.18,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFFFF3B3B),
                      Colors.transparent,
                    ],
                    radius: 1.2,
                  ),
                ),
              ),
            ),
          ),

          // ⭐ Compass / heading hologram (top center)
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  heading != null
                      ? "${heading!.toStringAsFixed(0)}°"
                      : "--°",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 18,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: Colors.redAccent.withOpacity(0.8),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 120,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.redAccent.withOpacity(0.0),
                        Colors.redAccent.withOpacity(0.8),
                        Colors.redAccent.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ⭐ Central speed energy ring + number
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow ring
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Colors.redAccent.withOpacity(0.1),
                          Colors.orangeAccent.withOpacity(0.4),
                          Colors.redAccent.withOpacity(0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.5),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  // Inner ring
                  Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.7),
                        width: 3,
                      ),
                    ),
                  ),
                  // Speed number
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        speed.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 120,
                          fontWeight: FontWeight.bold,
                          color: isSpeeding
                              ? Colors.orangeAccent
                              : Colors.redAccent,
                          shadows: [
                            Shadow(
                              color: (isSpeeding
                                      ? Colors.orangeAccent
                                      : Colors.redAccent)
                                  .withOpacity(0.9),
                              blurRadius: 40,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "MPH",
                        style: TextStyle(
                          fontSize: 22,
                          letterSpacing: 6,
                          color: Colors.white70,
                          shadows: [
                            Shadow(
                              color: Colors.redAccent.withOpacity(0.6),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ⭐ Waze-style speed limit bubble (right of speed)
          Positioned(
            right: 30,
            top: MediaQuery.of(context).size.height * 0.42,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSpeeding
                      ? Colors.orangeAccent
                      : Colors.redAccent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isSpeeding
                            ? Colors.orangeAccent
                            : Colors.redAccent)
                        .withOpacity(0.8),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "LIMIT",
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 2,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    speedLimit != null
                        ? "${speedLimit} MPH"
                        : "NO DATA",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSpeeding
                          ? Colors.orangeAccent
                          : Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ⭐ GPS Bars (top right, red neon)
          Positioned(
            top: 40,
            right: 24,
            child: Row(
              children: List.generate(4, (i) {
                final active = gpsBars > i;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: (i + 1) * 12,
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.redAccent
                        : Colors.redAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.8),
                              blurRadius: 12,
                            ),
                          ]
                        : [],
                  ),
                );
              }),
            ),
          ),

          // ⭐ Trip stats neon bar (bottom)
          Positioned(
            bottom: 26,
            left: 16,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.black.withOpacity(0.7),
                border: Border.all(
                  color: Colors.redAccent.withOpacity(0.7),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _stat(
                    "DIST",
                    "${(tripDistanceMeters / 1609).toStringAsFixed(2)} mi",
                  ),
                  _stat(
                    "TIME",
                    "${tripSeconds ~/ 60}m ${(tripSeconds % 60)}s",
                  ),
                  _stat(
                    "MAX",
                    "${maxSpeedMph.toStringAsFixed(0)} mph",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.redAccent.withOpacity(0.8),
            fontSize: 12,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
