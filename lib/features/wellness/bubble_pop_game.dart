import 'package:flutter/material.dart';
import 'package:sherise/features/wellness/services/wellness_audio_service.dart';

class BubblePopGame extends StatefulWidget {
  const BubblePopGame({super.key});

  @override
  State<BubblePopGame> createState() => _BubblePopGameState();
}

class _BubblePopGameState extends State<BubblePopGame> {
  final int _gridSize = 36; // Total bubbles
  List<bool> _popped = [];

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    setState(() {
      _popped = List.generate(_gridSize, (index) => false);
    });
  }

  void _popBubble(int index) {
    if (!_popped[index]) {
      WellnessAudioService().playSound(
        'pop.mp3',
        haptic: true,
        hapticType: HapticFeedbackType.light,
      );
      setState(() {
        _popped[index] = true;
      });
      // Auto-reset if all popped
      if (_popped.every((p) => p)) {
        Future.delayed(const Duration(milliseconds: 500), _resetGame);
      }
    }
  }

  @override
  void dispose() {
    WellnessAudioService().stopAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Bubble Wrap",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _resetGame,
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // Creating the look of the plastic sheet sitting on the surface
                color: const Color(0xFFF5F5F5).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00695C).withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Wrap(
                spacing: 4, // Tighter spacing for a continuous sheet look
                runSpacing: 4,
                children: List.generate(_gridSize, (index) {
                  return GestureDetector(
                    onTap: () => _popBubble(index),
                    child: _buildRealisticBubble(_popped[index]),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRealisticBubble(bool isPopped) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      // Slight size change to simulate deflation
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Base color: clear plastic on white looks very light grey/blueish
        // Made popped state darker/more visible so it doesn't "disappear"
        color: isPopped
            ? const Color(0xFFD6D6D6).withValues(
                alpha: 0.4,
              ) // Deflated plastic (visible grey)
            : const Color(
                0xFFF0F8FF,
              ).withValues(alpha: 0.2), // Inflated (AliceBlue hint)
        boxShadow: isPopped
            ? [
                // Popped: Flat shadow, but distinct enough to see the shape
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
                // Inner "sunken" shadow effect
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  spreadRadius: -2,
                ),
              ]
            : [
                // Inflated: Soft drop shadow for height
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(2, 4),
                ),
                // Inflated: Inner shadow at bottom right to suggest curvature
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  spreadRadius: -2,
                  offset: const Offset(-1, -1),
                ),
              ],
        gradient: isPopped
            ? null // Popped is messy/flat, no smooth gradient
            : RadialGradient(
                // The specular highlight is key for "glossy plastic" look
                center: const Alignment(-0.5, -0.6), // Top-left light source
                radius: 0.7,
                colors: [
                  Colors.white.withValues(
                    alpha: 0.9,
                  ), // Sharp Specular Highlight
                  Colors.white.withValues(alpha: 0.4), // Glare
                  Colors.transparent, // Clear plastic body
                  Colors.grey.withValues(alpha: 0.05), // Edge darkening
                ],
                stops: const [0.0, 0.15, 0.5, 1.0],
              ),
        border: Border.all(
          // Stronger border for popped to define the edge of the plastic
          color: isPopped
              ? Colors.grey.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.4),
          width: isPopped ? 1.0 : 0.5,
        ),
      ),
      child: isPopped
          ? Center(
              // "Wrinkle" effect for popped bubble
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.grey.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
                child: Center(
                  // Inner ring to look like crushed plastic center
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
