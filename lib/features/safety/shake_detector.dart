import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeDetector {
  final void Function() onPhoneShake;
  final double shakeThresholdGravity;
  final int minTimeBetweenShakes;
  final int shakeCountResetTime;
  final int minShakeCount;

  int _shakeCount = 0;
  int _lastShakeTimestamp = 0;
  StreamSubscription? _streamSubscription;

  ShakeDetector({
    required this.onPhoneShake,
    this.shakeThresholdGravity = 2.7,
    this.minTimeBetweenShakes = 1000,
    this.shakeCountResetTime = 3000,
    this.minShakeCount = 3,
  });

  void startListening() {
    _streamSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      double gX = event.x / 9.8;
      double gY = event.y / 9.8;
      double gZ = event.z / 9.8;

      // gForce will be close to 1 when there is no movement.
      double gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

      if (gForce > shakeThresholdGravity) {
        var now = DateTime.now().millisecondsSinceEpoch;
        
        // Reset shake count if too much time has passed
        if (_lastShakeTimestamp > 0 && 
            now - _lastShakeTimestamp > shakeCountResetTime) {
          _shakeCount = 0;
        }

        if (_lastShakeTimestamp == 0 || now - _lastShakeTimestamp > minTimeBetweenShakes) {
          _shakeCount++;
          _lastShakeTimestamp = now;
          
           if (_shakeCount >= minShakeCount) {
             _shakeCount = 0; // Reset after trigger
             onPhoneShake();
           }
        }
      }
    });
  }

  void stopListening() {
    _streamSubscription?.cancel();
  }
}
