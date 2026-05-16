import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'scooter_hud.dart';
import 'car_hud.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize foreground service
  await FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'speed_app_channel',
      channelName: 'Speed App Background Service',
      channelDescription: 'Keeps GPS and speed limit active',
      channelImportance: NotificationChannelImportance.HIGH,
      priority: NotificationPriority.HIGH,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: const ForegroundTaskOptions(
      interval: 1000,
      autoRunOnBoot: false,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );

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

  String mode = "bike";

  LatLng? currentLatLng;
  double? heading;

  double tripDistanceMeters = 0.0;
  int tripSeconds = 0;
  double maxSpeedMph = 0.0;

  bool batterySaver = false;

  @override
  void initState() {
    super.initState();
    initLocation();
    startForegroundService();
  }

  Future<void> startForegroundService() async {
    await FlutterForegroundTask.startService(
      notificationTitle: "Speed HUD Running",
      notificationText: "GPS + Speed Limit Active",
    );
  }

  @override
  void dispose() {
    FlutterForegroundTask.stopService();
    super.dispose();
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
      double rawSpeed = data.speed ?? 0.0;
      double mph = rawSpeed * 2.23694;

      if (mph < 2) mph = 0;

      setState(() {
        currentSpeed = mph;
        if (mph > maxSpeedMph) maxSpeedMph = mph;
      });

      if (rawSpeed > 0.5) {
        tripSeconds += 1;
        tripDistanceMeters += rawSpeed;
      }

      if (data.latitude != null && data.longitude != null) {
        currentLatLng = LatLng(data.latitude!, data.longitude!);
      }

      heading = data.heading;

      if (data.latitude != null && data.longitude != null) {
        fetchSpeedLimit(data.latitude!, data.longitude!);
      }

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

  // ⭐ OSM SPEED LIMITS (FREE)
  Future<void> fetchSpeedLimit(double lat, double lon) async {
    final url =
        "https://overpass-api.de/api/interpreter?data=[out:json];way(around:20,$lat,$lon)[\"maxspeed\"];out;";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["elements"] != null && data["elements"].isNotEmpty) {
          final tags = data["elements"][0]["tags"];
          final raw = tags["maxspeed"];

          if (raw != null) {
            int mphLimit;

            if (raw.contains("mph")) {
              mphLimit = int.parse(raw.replaceAll("mph", "").trim());
            } else {
              mphLimit = (int.parse(raw) * 0.621371).round();
            }

            setState(() => speedLimit = mphLimit);

            if (lastAnnouncedLimit == null ||
                mphLimit != lastAnnouncedLimit) {
              tts.speak("Speed limit is $mphLimit miles per hour");
            }

            lastAnnouncedLimit = mphLimit;
          }
        }
      }
    } catch (e) {
      print("OSM speed limit error: $e");
    }
  }

  void _resetTrip() {
    setState(() {
      tripDistanceMeters = 0.0;
      tripSeconds = 0;
      maxSpeedMph = 0.0;
    });
  }

  double get tripDistanceMiles => tripDistanceMeters / 1609.34;

  double get avgSpeedMph {
    if (tripSeconds == 0) return 0.0;
    final hours = tripSeconds / 3600.0;
    return tripDistanceMiles / hours;
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final bool isNight = hour < 6 || hour >= 19;

    return WithForegroundTask(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! < 0) {
                setState(() => mode = "car");
              } else {
                setState(() => mode = "bike");
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: mode == "bike"
                  ? (isNight
                      ? Colors.blueGrey.shade900
                      : Colors.blue.withOpacity(0.15))
                  : (isNight
                      ? Colors.red.shade900
                      : Colors.red.withOpacity(0.15)),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                    decoration: BoxDecoration(
                      color: mode == "bike"
                          ? Colors.blue.withOpacity(0.25)
                          : Colors.red.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: mode == "bike"
                              ? Colors.blue.withOpacity(0.5)
                              : Colors.red.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          mode == "bike"
                              ? Icons.pedal_bike
                              : Icons.directions_car,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          mode == "bike" ? "BIKE MODE" : "CAR MODE",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: mode == "bike"
                        ? ScooterHud(
                            currentSpeed: currentSpeed,
                            speedLimit: speedLimit,
                            currentLatLng: currentLatLng,
                            heading: heading,
                            tripDistanceMiles: tripDistanceMiles,
                            tripSeconds: tripSeconds,
                            avgSpeedMph: avgSpeedMph,
                            maxSpeedMph: maxSpeedMph,
                            isNight: isNight,
                            batterySaver: batterySaver,
                            onResetTrip: _resetTrip,
                            onToggleBatterySaver: () {
                              setState(() {
                                batterySaver = !batterySaver;
                              });
                            },
                          )
                        : CarHud(
                            currentSpeed: currentSpeed,
                            speedLimit: speedLimit,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

