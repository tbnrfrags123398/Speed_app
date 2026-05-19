import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:location/location.dart';

class GpsTaskHandler extends TaskHandler {
  final Location location = Location();

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    location.changeSettings(
      interval: 1000,
      accuracy: LocationAccuracy.high,
    );

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permission = await location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await location.requestPermission();
      if (permission != PermissionStatus.granted &&
          permission != PermissionStatus.grantedLimited) {
        return;
      }
    }

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
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {}

  @override
  Future<void> onRepeatEvent(
      DateTime timestamp, SendPort? sendPort) async {}

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {}
}
