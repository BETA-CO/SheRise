import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sherise/features/auth/data/biometric_service.dart';

class PinLockScreen extends StatefulWidget {
  final bool isSetup;
  final VoidCallback? onUnlock;
  final VoidCallback? onCancel;

  const PinLockScreen({
    super.key,
    this.isSetup = false,
    this.onUnlock,
    this.onCancel,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final BiometricService _biometricService = BiometricService();
  String _pin = "";
  String _confirmPin = "";
  bool _isConfirming = false;
  String _message = "Enter PIN";

  @override
  void initState() {
    super.initState();
    if (widget.isSetup) {
      _message = "Set a 4-digit PIN";
    } else {
      _message = "Enter PIN to Unlock";
      _triggerBiometric();
    }
  }

  Future<void> _triggerBiometric() async {
    if (await _biometricService.canCheckBiometrics()) {
      final authenticated = await _biometricService.authenticate();
      if (authenticated && mounted) {
        widget.onUnlock?.call();
      }
    }
  }

  void _onKeyPressed(String value) {
    if (_pin.length < 4) {
      setState(() {
        _pin += value;
      });
      if (_pin.length == 4) {
        _handlePinSubmit();
      }
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Future<void> _handlePinSubmit() async {
    if (widget.isSetup) {
      if (_isConfirming) {
        if (_pin == _confirmPin) {
          // Save PIN
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('app_pin', _pin);
          if (mounted) {
            Navigator.pop(context, true); // Return true indicating success
          }
        } else {
          setState(() {
            _message = "PINs do not match. Try again.";
            _pin = "";
            _confirmPin = "";
            _isConfirming = false;
          });
        }
      } else {
        setState(() {
          _confirmPin = _pin;
          _pin = "";
          _isConfirming = true;
          _message = "Confirm your PIN";
        });
      }
    } else {
      // Unlock mode
      final prefs = await SharedPreferences.getInstance();
      final storedPin = prefs.getString('app_pin');
      if (_pin == storedPin) {
        widget.onUnlock?.call();
      } else {
        setState(() {
          _message = "Incorrect PIN";
          _pin = "";
        });
      }
    }
  }

  Widget _buildPinDot(int index) {
    return Container(
      margin: const EdgeInsets.all(8),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: index < _pin.length ? Colors.pinkAccent : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildKey(String value) {
    return InkWell(
      onTap: () => _onKeyPressed(value),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade100,
        ),
        child: Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.isSetup
          ? AppBar(
              title: const Text("Set PIN"),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onCancel ?? () => Navigator.pop(context),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.lock_outline, size: 60, color: Colors.pinkAccent),
            const SizedBox(height: 20),
            Text(
              _message,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) => _buildPinDot(index)),
            ),
            const SizedBox(height: 60),
            // Keypad
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var j = 1; j <= 3; j++) _buildKey("${i * 3 + j}"),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (!widget.isSetup)
                    IconButton(
                      onPressed: _triggerBiometric,
                      icon: const Icon(Icons.fingerprint, size: 40),
                      color: Colors.pinkAccent,
                    )
                  else
                    const SizedBox(width: 80),
                  _buildKey("0"),
                  IconButton(
                    onPressed: _onDelete,
                    icon: const Icon(Icons.backspace_outlined),
                    iconSize: 30,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
