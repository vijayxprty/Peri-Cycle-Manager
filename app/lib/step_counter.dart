import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class StepCounter {
  StreamSubscription<StepCount>? _subscription;
  int? _baseline;

  Future<bool> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return (await Permission.activityRecognition.request()).isGranted;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return (await Permission.sensors.request()).isGranted;
    }
    return false;
  }

  Future<bool> get isGranted async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return (await Permission.activityRecognition.status).isGranted;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return (await Permission.sensors.status).isGranted;
    }
    return false;
  }

  Future<void> start(
    int savedSteps,
    void Function(int steps) onSteps,
    void Function(Object error) onError,
  ) async {
    await _subscription?.cancel();
    try {
      _subscription = Pedometer.stepCountStream.listen((event) {
        _baseline ??= event.steps - savedSteps;
        final sinceStarted = event.steps - _baseline!;
        onSteps(sinceStarted < 0 ? event.steps : sinceStarted);
      }, onError: (Object error) => onError(error));
    } catch (error) {
      onError(error);
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
