import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Service to handle audio playback and synchronized haptics for Wellness games.
class WellnessAudioService {
  static final WellnessAudioService _instance =
      WellnessAudioService._internal();

  factory WellnessAudioService() {
    return _instance;
  }

  WellnessAudioService._internal() {
    // Initialize a pool of players for SFX
    for (int i = 0; i < _poolSize; i++) {
      final player = AudioPlayer();
      player.setReleaseMode(ReleaseMode.stop);
      // Removed lowLatency mode as it causes issues on some devices
      _pool.add(player);
    }
  }

  static const int _poolSize = 10;
  final List<AudioPlayer> _pool = [];
  int _poolIndex = 0;

  // Cache for loaded sounds to prevent disk I/O lag
  final Map<String, BytesSource> _soundCache = {};

  // Separate player for loops
  final AudioPlayer _loopPlayer = AudioPlayer();

  /// Play a one-shot sound effect with optional haptic feedback.
  /// [assetPath] should be the filename in `lib/assets/sounds/`, e.g., 'pop.mp3'.
  Future<void> playSound(
    String assetPath, {
    bool haptic = false,
    HapticFeedbackType hapticType = HapticFeedbackType.light,
  }) async {
    try {
      BytesSource? source = _soundCache[assetPath];

      if (source == null) {
        try {
          final fullPath = 'lib/assets/sounds/$assetPath';
          final bytes = await rootBundle.load(fullPath);
          source = BytesSource(bytes.buffer.asUint8List());
          _soundCache[assetPath] = source;
        } catch (e) {
          debugPrint("Error loading sound $assetPath: $e");
          return;
        }
      }

      // Find a free player
      AudioPlayer? player;
      for (final p in _pool) {
        if (p.state != PlayerState.playing) {
          player = p;
          break;
        }
      }

      // If all busy, use round-robin
      if (player == null) {
        player = _pool[_poolIndex];
        _poolIndex = (_poolIndex + 1) % _poolSize;
        await player.stop();
      }

      await player.play(source);

      if (haptic) {
        triggerHaptic(hapticType);
      }
    } catch (e) {
      // Fail silently if audio fails, but STILL trigger haptics if requested
      if (haptic) {
        triggerHaptic(hapticType);
      }
      debugPrint("Audio Error for $assetPath: $e");
    }
  }

  /// Start a looping sound (e.g., raking sand).
  Future<void> startLoop(String assetPath) async {
    try {
      final fullPath = 'lib/assets/sounds/$assetPath';
      final bytes = await rootBundle.load(fullPath);
      final source = BytesSource(bytes.buffer.asUint8List());

      await _loopPlayer.setReleaseMode(ReleaseMode.loop);
      await _loopPlayer.play(source);
    } catch (e) {
      debugPrint("Audio Loop Error for $assetPath: $e");
    }
  }

  /// Stop the currently looping sound.
  Future<void> stopLoop() async {
    try {
      await _loopPlayer.stop();
      await _loopPlayer.setReleaseMode(ReleaseMode.stop);
    } catch (e) {
      debugPrint("Audio Stop Error: $e");
    }
  }

  /// Stop all playing sounds (useful for cleanup).
  Future<void> stopAll() async {
    try {
      for (final player in _pool) {
        await player.stop();
      }
      await _loopPlayer.stop();
      await _loopPlayer.setReleaseMode(ReleaseMode.stop);
    } catch (e) {
      debugPrint("Audio Stop All Error: $e");
    }
  }

  Future<void> triggerHaptic(HapticFeedbackType type) async {
    // Attempt to use the Vibration package to force feedback even if system haptics are off.
    bool hasVibrator = await Vibration.hasVibrator();

    if (hasVibrator) {
      switch (type) {
        case HapticFeedbackType.light:
          Vibration.vibrate(duration: 15);
          break;
        case HapticFeedbackType.medium:
          Vibration.vibrate(duration: 30);
          break;
        case HapticFeedbackType.heavy:
          Vibration.vibrate(duration: 60);
          break;
        case HapticFeedbackType.selection:
          Vibration.vibrate(duration: 10);
          break;
        case HapticFeedbackType.vibrate:
          Vibration.vibrate(duration: 500);
          break;
      }
    } else {
      // Fallback to standard HapticFeedback if Vibration package fails or no vibrator detected (though unlikely if hasVibrator is false)
      switch (type) {
        case HapticFeedbackType.light:
          HapticFeedback.lightImpact();
          break;
        case HapticFeedbackType.medium:
          HapticFeedback.mediumImpact();
          break;
        case HapticFeedbackType.heavy:
          HapticFeedback.heavyImpact();
          break;
        case HapticFeedbackType.selection:
          HapticFeedback.selectionClick();
          break;
        case HapticFeedbackType.vibrate:
          HapticFeedback.vibrate();
          break;
      }
    }
  }
}

enum HapticFeedbackType { light, medium, heavy, selection, vibrate }
