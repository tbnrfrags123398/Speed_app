import 'package:flutter/material.dart';
import 'dart:ui';

class PerformanceScreen extends StatelessWidget {
  final double speed;
  final double accel;
  final double horsepower;
  final List<double> hpHistory;
  final VoidCallback onSwipeLeft;

  const PerformanceScreen({
    super.key,
    required this.speed,
    required this.accel,
    required this.horsepower,
    required this.hpHistory,
    required this.onSwipeLeft,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null &&
            details.primaryVelocity! > 0) {
          onSwipeLeft();
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                // ⭐ LEFT SIDE — STATS
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "PERFORMANCE",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // SPEED
                        Text(
                          "Speed: ${speed.toStringAsFixed(1)} MPH",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // ACCEL
                        Text(
                          "Accel: ${(accel * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // HORSEPOWER
                        Text(
                          "Horsepower: ${horsepower.toStringAsFixed(0)} HP",
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // PEAK HP
                        Text(
                          "Peak HP: ${_peakHP().toStringAsFixed(0)}",
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // 0–60 (FAKE SIM)
                        Text(
                          "0–60: ${_fakeZeroToSixty().toStringAsFixed(2)}s",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                          ),
                        ),

                        const Spacer(),

                        // BACK BUTTON
                        GestureDetector(
                          onTap: onSwipeLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.redAccent, width: 2),
                            ),
                            child: const Text(
                              "← BACK TO HUD",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ⭐ RIGHT SIDE — DYNO GRAPH
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: CustomPaint(
                      painter: DynoGraphPainter(hpHistory),
                      child: Container(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _peakHP() {
    if (hpHistory.isEmpty) return horsepower;
    return hpHistory.reduce((a, b) => a > b ? a : b);
  }

  double _fakeZeroToSixty() {
    // Simulated 0–60 time based on accel
    if (accel <= 0) return 6.5;
    return (6.5 / (accel + 0.1)).clamp(2.8, 6.5);
  }
}

// ⭐ DYNO GRAPH PAINTER — RED NEON LINE
class DynoGraphPainter extends CustomPainter {
  final List<double> hpHistory;

  DynoGraphPainter(this.hpHistory);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path();

    if (hpHistory.isEmpty) return;

    double maxHP = hpHistory.reduce((a, b) => a > b ? a : b);
    maxHP = maxHP < 1 ? 1 : maxHP;

    for (int i = 0; i < hpHistory.length; i++) {
      final x = (i / hpHistory.length) * size.width;
      final y = size.height -
          ((hpHistory[i] / maxHP) * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant DynoGraphPainter oldDelegate) {
    return true;
  }
}
