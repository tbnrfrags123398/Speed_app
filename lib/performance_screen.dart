import 'dart:ui';
import 'package:flutter/material.dart';

class PerformanceScreen extends StatelessWidget {
  final double speed;
  final double accel;
  final double horsepower;
  final List<double> hpHistory;
  final int zeroTo30Ms;
  final int zeroTo60Ms;
  final VoidCallback onSwipeLeft;

  const PerformanceScreen({
    super.key,
    required this.speed,
    required this.accel,
    required this.horsepower,
    required this.hpHistory,
    required this.zeroTo30Ms,
    required this.zeroTo60Ms,
    required this.onSwipeLeft,
  });

  @override
  Widget build(BuildContext context) {
    final double displaySpeed = speed.clamp(0, 9999);

    String _formatMs(int ms) {
      if (ms <= 0) return "--.--s";
      return (ms / 1000.0).toStringAsFixed(2) + "s";
    }

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
                // LEFT SIDE — STATS
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

                        Text(
                          "Speed: ${displaySpeed.toStringAsFixed(1)} MPH",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Text(
                          "Accel: ${(accel * 100).clamp(0, 100).toStringAsFixed(0)}%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Text(
                          "Horsepower: ${horsepower.toStringAsFixed(0)} HP",
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 30),

                        Text(
                          "Peak HP: ${_peakHP().toStringAsFixed(0)}",
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 30),

                        Text(
                          "0–30: ${_formatMs(zeroTo30Ms)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "0–60: ${_formatMs(zeroTo60Ms)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                          ),
                        ),

                        const Spacer(),

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

                // RIGHT SIDE — DYNO GRAPH
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
}

// DYNO GRAPH PAINTER
class DynoGraphPainter extends CustomPainter {
  final List<double> hpHistory;

  DynoGraphPainter(this.hpHistory);

  @override
  void paint(Canvas canvas, Size size) {
    if (hpHistory.isEmpty) return;

    final paint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path();

    double maxHP = hpHistory.reduce((a, b) => a > b ? a : b);
    maxHP = maxHP < 1 ? 1 : maxHP;

    for (int i = 0; i < hpHistory.length; i++) {
      final double x =
          (i / (hpHistory.length - 1).clamp(1, 9999)) * size.width;
      final double y =
          size.height - ((hpHistory[i] / maxHP) * size.height);

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
