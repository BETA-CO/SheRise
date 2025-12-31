import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BubblePopGame extends StatefulWidget {
  const BubblePopGame({super.key});

  @override
  State<BubblePopGame> createState() => _BubblePopGameState();
}

class _BubblePopGameState extends State<BubblePopGame> {
  final int _gridSize = 30; // Total bubbles
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
      HapticFeedback.lightImpact();
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bubble Wrap"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _resetGame),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: List.generate(_gridSize, (index) {
              return GestureDetector(
                onTap: () => _popBubble(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _popped[index]
                        ? Colors.grey.withOpacity(0.2)
                        : Colors.pinkAccent.withOpacity(0.6),
                    boxShadow: _popped[index]
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.pinkAccent.withOpacity(0.3),
                              blurRadius: 5,
                              spreadRadius: 2,
                              offset: const Offset(2, 2),
                            ),
                            const BoxShadow(
                              color: Colors.white,
                              blurRadius: 5,
                              spreadRadius: 2,
                              offset: Offset(-2, -2),
                            ),
                          ],
                    gradient: _popped[index]
                        ? null
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.pinkAccent.shade100,
                              Colors.pinkAccent.shade400,
                            ],
                          ),
                  ),
                  child: Center(
                    child: _popped[index]
                        ? const Icon(Icons.check, size: 30, color: Colors.grey)
                        : null,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
