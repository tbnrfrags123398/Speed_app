import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'scooter_hud.dart';
import 'car_hud.dart';

void main() {
  runApp(const SpeedApp());
}

class SpeedApp extends StatefulWidget {
  const SpeedApp({super.key});

  @override
  State<SpeedApp> createState() => _SpeedAppState();
}

class _SpeedAppState extends State<SpeedApp> {
  final Location location = Location();
  final FlutterTts tts = FlutterTts();

  double currentSpeed = 0.0;
  int? speedLimit;

  bool hasWarned = false;
  int? lastAnnouncedLimit;
  String mode = "bike"; // default mode

  @override
  void initState() {
    super.initState();
    initLocation();
  }

  Future<void> initLocation() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
    }

    PermissionStatus permission = await location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await location.requestPermission();
    }

    location.changeSettings(interval: 1000);

    location.onLocationChanged.listen((LocationData data) {
      // SPEED UPDATE
      double rawSpeed = data.speed ?? 0.0;
      double mph = rawSpeed * 2.23694;

      if (mph < 2) {
        mph = 0;
      }

      setState(() {
        currentSpeed = mph;
      });

      // SPEED LIMIT FETCH
      if (data.latitude != null && data.longitude != null) {
        fetchSpeedLimit(data.latitude!, data.longitude!);
      }

      // SPEEDING WARNING
      if (speedLimit != null) {
        if (currentSpeed > speedLimit! + 5) {
          if (!hasWarned) {
            tts.speak("Slow down");
            hasWarned = true;
          }
        } else {
          hasWarned = false;
        }
      }
    });
  }

  Future<void> fetchSpeedLimit(double lat, double lon) async {
    const apiKey = "YOUR_HERE_API_KEY";

    final url =
        "https://router.hereapi.com/v8/routes?transportMode=car&origin=$lat,$lon&destination=$lat,$lon&return=summary&apikey=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      final json = jsonDecode(response.body);

      final limit = json["routes"]?[0]["sections"]?[0]["summary"]?["speedLimit"];

      if (limit != null) {
        int mphLimit = (limit * 2.23694).round();

        setState(() {
          speedLimit = mphLimit;
        });

        if (lastAnnouncedLimit == null) {
          tts.speak("Speed limit is $mphLimit miles per hour");
        } else if (mphLimit < lastAnnouncedLimit!) {
          tts.speak("Speed limit reduced to $mphLimit miles per hour");
        } else if (mphLimit > lastAnnouncedLimit!) {
          tts.speak("Speed limit is $mphLimit miles per hour");
        }

        lastAnnouncedLimit = mphLimit;
      }
    } catch (e) {
      print("Speed limit error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      mode = "bike";
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 25, vertical: 12),
                    decoration: BoxDecoration(
                      color: mode == "bike"
                          ? Colors.green
                          : Colors.grey[800],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "BIKE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                GestureDetector(
                  onTap: () {
                    setState(() {
                      mode = "car";
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 25, vertical: 12),
                    decoration: BoxDecoration(
                      color: mode == "car"
                          ? Colors.blue
                          : Colors.grey[800],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "CAR",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Expanded(
              child: mode == "bike"
                  ? ScooterHud(
                      currentSpeed: currentSpeed,
                      speedLimit: speedLimit,
                    )
                  : CarHud(
                      currentSpeed: currentSpeed,
                      speedLimit: speedLimit,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

