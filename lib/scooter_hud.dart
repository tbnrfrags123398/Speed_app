import 'package:flutter/material.dart';

class ScooterHud extends StatelessWidget {
  final double currentSpeed;
  final int? speedLimit;

  const ScooterHud({
    super.key,
    required this.currentSpeed,
    required this.speedLimit,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSpeeding =
        speedLimit != null && currentSpeed > speedLimit!;

    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (speedLimit != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${speedLimit!}",
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),

            const SizedBox(height: 40),

            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSpeeding ? Colors.red.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                currentSpeed.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 160,
                  fontWeight: FontWeight.w900,
                  color: isSpeeding ? Colors.red : Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "MPH",
              style: TextStyle(
                fontSize: 40,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
