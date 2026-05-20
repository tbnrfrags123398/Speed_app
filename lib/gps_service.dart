import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:location/location.dart';

class GpsTaskHandler extends TaskHandler {
  final Location location = Location();

  double _lastSpeedMps = 0.0;
  double _lastHeading = 0.0;
  bool _lowPowerMode = false;
  int _idleTicks = 0; // how many seconds we've basically been stopped

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
      final double rawSpeedMps = data.speed ?? 0.0;
      final double rawHeading = data.heading ?? _lastHeading;

      // Low‑pass filter for speed + heading (smoothing)
      const double alpha = 0.3;
      _lastSpeedMps = _lastSpeedMps + (rawSpeedMps - _lastSpeedMps) * alpha;
      _lastHeading = _lastHeading + (rawHeading - _lastHeading) * alpha;

      final double mph = _lastSpeedMps * 2.23694;

      // Battery‑optimized mode: if basically stopped for a while, slow updates
      if (mph < 1.0) {
        _idleTicks++;
      } else {
        _idleTicks = 0;
      }

      if (!_lowPowerMode && _idleTicks > 10) {
        _lowPowerMode = true;
        location.changeSettings(
          interval: 3000,
          accuracy: LocationAccuracy.balanced,
        );
      } else if (_lowPowerMode && mph >= 3.0) {
        _lowPowerMode = false;
        location.changeSettings(
          interval: 1000,
          accuracy: LocationAccuracy.high,
        );
      }

      // GPS Bars based on accuracy
      final double acc = data.accuracy ?? 50;
      int bars = 1;
      if (acc < 5) {
        bars = 5;
      } else if (acc < 10) {
        bars = 4;
      } else if (acc < 20) {
        bars = 3;
      } else if (acc < 40) {
        bars = 2;
      }

      sendPort?.send({
        "speed": mph,
        "lat": data.latitude,
        "lon": data.longitude,
        "heading": _lastHeading,
        "gpsBars": bars,
      });
    });
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {}

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {}

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {}
}
