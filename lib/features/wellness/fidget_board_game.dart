import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sherise/features/wellness/services/wellness_audio_service.dart';

class FidgetBoardGame extends StatelessWidget {
  const FidgetBoardGame({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Fidget Lab",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
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
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSectionTitle("Switches"),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: [
                    const _ToggleSwitch(),
                    const _ToggleSwitch(),
                    const _ToggleSwitch(),
                  ],
                ),
                const SizedBox(height: 40),
                _buildSectionTitle("Buttons"),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: [
                    const _HapticButton(color: Color(0xFF00695C)),
                    const _HapticButton(color: Colors.tealAccent),
                    const _HapticButton(color: Color(0xFF26A69A)),
                  ],
                ),
                const SizedBox(height: 40),
                _buildSectionTitle("Slider"),
                const SizedBox(height: 20),
                const _HapticSlider(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: Colors.grey[500],
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _ToggleSwitch extends StatefulWidget {
  const _ToggleSwitch();

  @override
  State<_ToggleSwitch> createState() => _ToggleSwitchState();
}

class _ToggleSwitchState extends State<_ToggleSwitch> {
  bool _isOn = false;

  void _toggle() {
    WellnessAudioService().playSound(
      'switch_click.mp3',
      haptic: true,
      hapticType: HapticFeedbackType.heavy,
    );
    setState(() {
      _isOn = !_isOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Switch Background Groove
            Container(
              width: 10,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // The Lever
            AnimatedAlign(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOutBack,
              alignment: _isOn
                  ? const Alignment(0, -0.6)
                  : const Alignment(0, 0.6),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.grey.shade100, Colors.grey.shade300],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isOn
                          ? const Color(0xFF00695C)
                          : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HapticButton extends StatefulWidget {
  final Color color;
  const _HapticButton({required this.color});

  @override
  State<_HapticButton> createState() => _HapticButtonState();
}

class _HapticButtonState extends State<_HapticButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        WellnessAudioService().playSound(
          'button_press.mp3',
          haptic: true,
          hapticType: HapticFeedbackType.medium,
        );
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        HapticFeedback.lightImpact(); // Release feel
        setState(() => _isPressed = false);
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 50),
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: _isPressed ? 0.6 : 1.0),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [widget.color.withValues(alpha: 0.8), widget.color],
              ),
              boxShadow: _isPressed
                  ? []
                  : [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            padding: EdgeInsets.only(
              top: _isPressed ? 2 : 0,
            ), // Physical sink effect
            child: const Icon(
              Icons.power_settings_new,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _HapticSlider extends StatefulWidget {
  const _HapticSlider();

  @override
  State<_HapticSlider> createState() => _HapticSliderState();
}

class _HapticSliderState extends State<_HapticSlider> {
  double _value = 0.5;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 10,
          activeTrackColor: Colors.grey.shade400,
          inactiveTrackColor: Colors.grey.shade200,
          thumbColor: Colors.white,
          thumbShape: const RoundSliderThumbShape(
            enabledThumbRadius: 15,
            elevation: 5,
          ),
          overlayColor: Colors.grey.withValues(alpha: 0.1),
        ),
        child: Slider(
          value: _value,
          onChanged: (val) {
            // Haptic tick every 10%
            if ((val * 10).floor() != (_value * 10).floor()) {
              HapticFeedback.selectionClick();
            }
            setState(() => _value = val);
          },
        ),
      ),
    );
  }
}
