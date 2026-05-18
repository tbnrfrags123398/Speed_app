import 'package:flutter/material.dart';

class CarHUD extends StatelessWidget {
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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Text(
                  "${speedLimit!}",
                  style: const TextStyle(
                    fontSize: 55,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),

            const SizedBox(height: 40),

            Text(
              currentSpeed.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 110,
                fontWeight: FontWeight.bold,
                color: isSpeeding ? Colors.yellow : Colors.white,
                shadows: [
                  Shadow(
                    color: isSpeeding
                        ? Colors.yellowAccent
                        : Colors.blueAccent,
                    blurRadius: 20,
                  )
                ],
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
