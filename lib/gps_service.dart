import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:location/location.dart';

class GpsTaskHandler extends TaskHandler {
  Location location = Location();

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    // Configure GPS update interval
    location.changeSettings(
      interval: 1000, // 1 second
      accuracy: LocationAccuracy.high,
    );

    // Ensure permissions
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
    }

    PermissionStatus permission = await location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await location.requestPermission();
    }

    // Start listening to GPS
    location.onLocationChanged.listen((data) {
      final speedMps = data.speed ?? 0.0;
      final mph = speedMps * 2.23694;

      sendPort?.send({
        "speed": mph,
        "lat": data.latitude,
        "lon": data.longitude,
        "heading": data.heading,
      });
    });
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    // Not used, but required by interface
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    // Cleanup if needed
  }
}

