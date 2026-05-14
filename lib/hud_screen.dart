import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class HudScreen extends StatefulWidget {
  final double currentSpeed;
  final int? speedLimit;

  const HudScreen({
    super.key,
    required this.currentSpeed,
    required this.speedLimit,
  });

  @override
  State<HudScreen> createState() => _HudScreenState();
}

class _HudScreenState extends State<HudScreen> {
  final FlutterTts tts = FlutterTts();
  bool hasWarned = false;

  @override
  void initState() {
    super.initState();
    tts.setSpeechRate(0.6);
    tts.setVolume(1.0);
  }

  @override
  Widget build(BuildContext context) {
    final bool speeding = widget.speedLimit != null &&
        widget.currentSpeed > widget.speedLimit!;

    // Voice alert
    if (speeding && !hasWarned) {
      hasWarned = true;
      tts.speak("Slow down");
    }
    if (!speeding) {
      hasWarned = false;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Speed Limit Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: speeding ? Colors.red : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.speedLimit?.toString() ?? "--",
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: speeding ? Colors.white : Colors.black,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Current Speed
            Text(
              widget.currentSpeed.toStringAsFixed(0),
              style: const TextStyle(
                fontSize: 140,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
