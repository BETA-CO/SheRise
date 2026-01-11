import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sherise/features/wellness/services/wellness_audio_service.dart';

class ParticleFlowGame extends StatefulWidget {
  const ParticleFlowGame({super.key});

  @override
  State<ParticleFlowGame> createState() => _ParticleFlowGameState();
}

class _ParticleFlowGameState extends State<ParticleFlowGame>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<_InkParticle> _particles = [];
  Offset? _touchPosition;
  final Random _random = Random();

  // Ink Palette: Cyan, Magenta, Deep Blue, Purple
  final List<Color> _inkColors = [
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFFE91E63), // Pink/Magenta
    const Color(0xFF3F51B5), // Indigo
    const Color(0xFF9C27B0), // Purple
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    WellnessAudioService().stopAll();
    super.dispose();
  }

  // ... (existing code)

  void _onPanStart(DragStartDetails details) {
    // Start loop by setting touch position (will cause _onTick to resume updates)
    setState(() {
      _touchPosition = details.localPosition;
    });
    WellnessAudioService().startLoop('ink_spwan.mp3');
    WellnessAudioService().playSound(
      'ink_spwan.mp3',
      haptic: true,
      hapticType: HapticFeedbackType.light,
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // Continuous feedback while gliding (drawing ink)
    if (_touchPosition != null) {
      final distance = (details.localPosition - _touchPosition!).distance;
      if (distance > 3.0) {
        // Threshold for smoothness
        WellnessAudioService().triggerHaptic(HapticFeedbackType.selection);
      }
    }
    _touchPosition = details.localPosition;
  }

  void _onPanEnd(DragEndDetails details) {
    _touchPosition = null;
    WellnessAudioService().stopLoop();
  }

  void _onPanCancel() {
    _touchPosition = null;
    WellnessAudioService().stopLoop();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;

    // Optimization: Stop the loop if nothing is happening
    if (_particles.isEmpty && _touchPosition == null) {
      return;
    }

    setState(() {
      // 1. Spawn new particles if touching
      if (_touchPosition != null) {
        for (int i = 0; i < 5; i++) {
          _particles.add(
            _InkParticle(
              position: _touchPosition!,
              color: _inkColors[_random.nextInt(_inkColors.length)],
              velocity: Offset(
                (_random.nextDouble() - 0.5) * 5.0,
                (_random.nextDouble() - 0.5) * 5.0,
              ),
              radius: _random.nextDouble() * 10 + 5,
            ),
          );
        }
      }

      // 2. Update existing particles
      for (var p in _particles) {
        p.update();
      }

      // 3. Remove dead particles
      _particles.removeWhere((p) => p.life <= 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White paper background
      appBar: AppBar(
        title: const Text(
          "Ink Flow",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _particles.clear();
              });
            },
          ),
        ],
      ),
      body: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onPanCancel: _onPanCancel,
        child: Container(
          color: Colors.white,
          width: double.infinity,
          height: double.infinity,
          child: CustomPaint(painter: _InkPainter(_particles)),
        ),
      ),
    );
  }
}

class _InkParticle {
  Offset position;
  Offset velocity;
  final Color color;
  double radius;
  double life = 1.0;
  double decay = 0.005; // Fade speed

  _InkParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.radius,
  });

  void update() {
    position += velocity;
    // Friction (viscosity)
    velocity *= 0.95;
    // Slowly grow/spread like ink
    radius += 0.1;
    // Fade out
    life -= decay;
  }
}

class _InkPainter extends CustomPainter {
  final List<_InkParticle> particles;

  _InkPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      if (p.life <= 0) continue;

      final paint = Paint()
        ..color = p.color
            .withValues(alpha: p.life * 0.4) // Semi-transparent ink
        ..style = PaintingStyle.fill;

      // Blur to simulate liquid/ink bleeding
      // Note: Real-time blur on many particles is expensive.
      // We rely on transparency stacking for the "wet" look.

      canvas.drawCircle(p.position, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _InkPainter oldDelegate) {
    return true;
  }
}
