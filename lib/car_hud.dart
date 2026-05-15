import 'package:flutter/material.dart';

class CarHud extends StatelessWidget {
  final double currentSpeed;
  final int? speedLimit;

  const CarHud({
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
                padding: const EdgeInsets.all(25),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  "${speedLimit!}",
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),

            const SizedBox(height: 40),

            Text(
              currentSpeed.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 100,
                fontWeight: FontWeight.bold,
                color: isSpeeding ? Colors.yellow : Colors.white,
              ),
            ),

            const Text(
              "MPH",
              style: TextStyle(
                fontSize: 35,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
