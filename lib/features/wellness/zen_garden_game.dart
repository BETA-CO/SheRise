import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sherise/features/wellness/services/wellness_audio_service.dart';

class ZenGardenGame extends StatefulWidget {
  const ZenGardenGame({super.key});

  @override
  State<ZenGardenGame> createState() => _ZenGardenGameState();
}

class _ZenGardenGameState extends State<ZenGardenGame> {
  // Lists of paths. Each path is a list of Offset points.
  final List<List<Offset>> _paths = [];
  List<Offset> _currentPath = [];

  @override
  void dispose() {
    WellnessAudioService().stopAll();
    super.dispose();
  }

  // ... (existing code methods to be updated or added) ...
  // Since replace_file_content works on contiguous blocks, I'll update the pan methods together.

  void _onPanStart(DragStartDetails details) {
    WellnessAudioService().startLoop('sand_rake.mp3');
    setState(() {
      _currentPath = [details.localPosition];
      _paths.add(_currentPath);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // Generate haptic texture based on movement distance
    // This provides a physical "grit" feeling synchronized with the rake sound
    if (_currentPath.isNotEmpty) {
      final distance = (details.localPosition - _currentPath.last).distance;
      if (distance > 3.0) {
        // Lower threshold for more continuous/smoother feel
        WellnessAudioService().triggerHaptic(HapticFeedbackType.selection);
      }
    }
    setState(() {
      _currentPath.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    WellnessAudioService().stopLoop();
  }

  void _onPanCancel() {
    WellnessAudioService().stopLoop();
  }

  void _resetGarden() {
    // Note: 'sand_smooth.mp3' is missing, using haptic only.
    HapticFeedback.mediumImpact();
    setState(() {
      _paths.clear();
      _currentPath = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Zen Garden",
          style: TextStyle(
            color: Color(0xFF00695C),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00695C)),
        actions: [
          IconButton(
            icon: const Icon(Icons.waves),
            tooltip: "Smooth Sand",
            onPressed: _resetGarden,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF2FCF9), // Pale Mint Sand
        ),
        child: Stack(
          children: [
            // The Sand Canvas
            GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              onPanCancel: _onPanCancel,
              child: CustomPaint(
                painter: _SandRakePainter(_paths),
                size: Size.infinite,
              ),
            ),
            // Tutorial / Hint
            if (_paths.isEmpty)
              const Center(
                child: Text(
                  "Drag to rake the sand",
                  style: TextStyle(
                    color: Colors.black26,
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _resetGarden,
        backgroundColor: const Color(0xFF00695C),
        child: const Icon(Icons.cleaning_services, color: Colors.white),
      ),
    );
  }
}

class _SandRakePainter extends CustomPainter {
  final List<List<Offset>> paths;

  _SandRakePainter(this.paths);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw minimal texture noise (optional, simulating sand grains could be expensive)

    // 2. Painting the raked grooves
    // To simulate a groove: visible shadow (darker sand) inside, slight highlight on edge.

    final paintShadow = Paint()
      ..color = const Color(0xFF00695C)
          .withValues(alpha: 0.2) // Teal shadow
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 20.0;

    // paintHighlight removed as it was unused and we are sticking to a clean subtle groove look.

    // Rake Effect: Draw multiple parallel lines for one finger drag
    // Ideally we offset the path.
    // Simpler approach for "Zen": One deep groove.

    for (final path in paths) {
      if (path.length < 2) continue;

      final pathObj = Path();
      pathObj.moveTo(path.first.dx, path.first.dy);
      for (int i = 1; i < path.length; i++) {
        pathObj.lineTo(path[i].dx, path[i].dy);
      }

      // Draw the main groove shadow
      canvas.drawPath(pathObj, paintShadow);

      // Draw minimal highlight offset to give depth (simulating light coming from top left)
      // canvas.drawPath(pathObj.shift(Offset(-2, -2)), paintHighlight); // This might look weird if direction changes.

      // Better Rake Effect: A "comb" look?
      // Let's stick to a wide, soft groove which is very satisfying.

      // Inner line to sharpen the groove bottom
      final paintInner = Paint()
        ..color = const Color(0xFF00695C).withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 8.0;

      canvas.drawPath(pathObj, paintInner);
    }
  }

  @override
  bool shouldRepaint(covariant _SandRakePainter oldDelegate) {
    return true; // Repaint when paths change
  }
}
