import 'package:flutter/material.dart';

class CarHUD extends StatelessWidget {
  final double speed;
  final double accel;
  final double horsepower;
  final VoidCallback onSwipeRight;

  const CarHUD({
    super.key,
    required this.speed,
    required this.accel,
    required this.horsepower,
    required this.onSwipeRight,
  });

  @override
  Widget build(BuildContext context) {
    final double displaySpeed = speed.clamp(0, 9999);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
          onSwipeRight();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // MODE LABEL
            Positioned(
              top: MediaQuery.of(context).size.height * 0.25,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "CAR MODE",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.25),
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),

            // MAIN HUD CONTENT
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // SPEED
                Text(
                  displaySpeed.toStringAsFixed(1),
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

                // ACCELERATION BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      const Text(
                        "ACCELERATION",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: accel.clamp(0, 1),
                        minHeight: 10,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // HORSEPOWER
                Text(
                  "${horsepower.toStringAsFixed(0)} HP",
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 60),

                // PERFORMANCE PANEL BUTTON
                GestureDetector(
                  onTap: onSwipeRight,
                  child: Container(
                    width: 260,
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.redAccent, width: 2),
                    ),
                    child: const Center(
                      child: Text(
                        "OPEN PERFORMANCE SCREEN →",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

