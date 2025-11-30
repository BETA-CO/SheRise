import 'package:flutter/material.dart';
import 'dart:math';

class SlideToAct extends StatefulWidget {
  final String text;
  final VoidCallback onSlideCompleted;
  final Color outerColor;
  final Color innerColor;
  final TextStyle? textStyle;

  const SlideToAct({
    super.key,
    required this.text,
    required this.onSlideCompleted,
    this.outerColor = Colors.white,
    this.innerColor = const Color(0xFFFF8BA7),
    this.textStyle,
  });

  @override
  State<SlideToAct> createState() => _SlideToActState();
}

class _SlideToActState extends State<SlideToAct> {
  double _position = 0;
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final sliderWidth = 60.0;
        final maxDrag = maxWidth - sliderWidth - 10; // 10 is padding

        return Container(
          height: 60,
          width: maxWidth,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: widget.outerColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Text
              Center(
                child: AnimatedOpacity(
                  opacity: _position > 0 ? 0.5 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    widget.text,
                    style:
                        widget.textStyle ??
                        const TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ),

              // Slider
              Positioned(
                left: _position,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_submitted) return;
                    setState(() {
                      _position = max(
                        0,
                        min(_position + details.delta.dx, maxDrag),
                      );
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_submitted) return;
                    if (_position >= maxDrag * 0.85) {
                      // Completed
                      setState(() {
                        _position = maxDrag;
                        _submitted = true;
                      });
                      widget.onSlideCompleted();
                    } else {
                      // Reset
                      setState(() {
                        _position = 0;
                      });
                    }
                  },
                  child: Container(
                    height: 50,
                    width: sliderWidth,
                    decoration: BoxDecoration(
                      color: widget.innerColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.innerColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
