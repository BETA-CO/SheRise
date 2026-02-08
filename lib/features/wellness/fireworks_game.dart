import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:sherise/features/wellness/services/wellness_audio_service.dart';

class FireworksGame extends StatefulWidget {
  const FireworksGame({super.key});

  @override
  State<FireworksGame> createState() => _FireworksGameState();
}

class _FireworksGameState extends State<FireworksGame>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<_Firework> _fireworks = [];
  final Random _random = Random();

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

  void _onTick(Duration elapsed) {
    if (!mounted) return;

    // Optimization: Pause updates if no fireworks exist
    if (_fireworks.isEmpty) return;

    setState(() {
      for (var fw in _fireworks) {
        fw.update();
      }
      _fireworks.removeWhere((fw) => fw.isDead);
    });
  }

  void _launchFirework(TapUpDetails details) {
    // Launch a firework at the tap position
    HapticFeedback.mediumImpact();
    setState(() {
      _fireworks.add(
        _Firework(
          target: details.localPosition,
          color: HSLColor.fromAHSL(
            1.0,
            _random.nextDouble() * 360,
            0.7,
            0.5,
          ).toColor(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Ink Bursts",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: () {
              setState(() {
                _fireworks.clear();
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 234, 245, 255),
              Color(0xFFF5FAFF),
              Colors.white,
            ],
            stops: [0.40, 0.60, 1.0],
          ),
        ),
        child: GestureDetector(
          onTapUp: _launchFirework,
          child: Container(
            color: Colors.transparent,
            width: double.infinity,
            height: double.infinity,
            child: CustomPaint(painter: _FireworkPainter(_fireworks)),
          ),
        ),
      ),
    );
  }
}

class _Firework {
  Offset position;
  Offset? target;
  Color color;
  bool exploded = false;
  List<_Particle> particles = [];
  bool isDead = false;

  // Rocket phase
  Offset startPos;
  double progress = 0.0;

  _Firework({required this.target, required this.color})
    : position = Offset(target!.dx, 800), // Start from bottom
      startPos = Offset(target.dx, 800);

  void update() {
    if (!exploded) {
      // Rocket rising (Linear interpolation for simplicity, or physics)
      // Moving fast to target
      position = Offset.lerp(startPos, target!, progress)!;
      progress += 0.05;

      if (progress >= 1.0) {
        exploded = true;
        _explode();
      }
    } else {
      // Particles falling
      bool allDead = true;
      for (var p in particles) {
        p.update();
        if (p.life > 0) allDead = false;
      }
      if (allDead) isDead = true;
    }
  }

  void _explode() {
    WellnessAudioService().playSound(
      'firework_explosion.mp3',
      haptic: true,
      hapticType: HapticFeedbackType.heavy,
    );
    // Spawn particles
    for (int i = 0; i < 50; i++) {
      double angle = (pi * 2 * i) / 50;
      double speed = Random().nextDouble() * 3 + 1;
      particles.add(
        _Particle(
          position: position,
          velocity: Offset(cos(angle) * speed, sin(angle) * speed),
          color: color,
        ),
      );
    }
  }
}

class _Particle {
  Offset position;
  Offset velocity;
  Color color;
  double life = 1.0;
  double gravity = 0.1;

  _Particle({
    required this.position,
    required this.velocity,
    required this.color,
  });

  void update() {
    velocity += Offset(0, gravity);
    position += velocity;
    life -= 0.02;
  }
}

class _FireworkPainter extends CustomPainter {
  final List<_Firework> fireworks;

  _FireworkPainter(this.fireworks);

  @override
  void paint(Canvas canvas, Size size) {
    for (var fw in fireworks) {
      if (!fw.exploded) {
        // Draw rising rocket stroke
        final paint = Paint()
          ..color = fw.color
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 4.0;
        canvas.drawLine(
          fw.position,
          fw.position + Offset(0, 15), // Trail
          paint,
        );
      } else {
        // Draw burst particles
        for (var p in fw.particles) {
          if (p.life <= 0) continue;
          final paint = Paint()
            ..color = p.color.withValues(alpha: p.life)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(p.position, 2.0 * p.life + 1.0, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FireworkPainter oldDelegate) {
    return true;
  }
}
