import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sherise/features/auth/presentation/pages/setup_page.dart';
import 'package:sherise/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:provider/provider.dart';

class CaptchaPage extends StatefulWidget {
  final String name;
  final String surname;
  final DateTime dob;

  const CaptchaPage({
    super.key,
    required this.name,
    required this.surname,
    required this.dob,
  });

  @override
  State<CaptchaPage> createState() => _CaptchaPageState();
}

class _CaptchaPageState extends State<CaptchaPage> {
  double _sliderValue = 0.0;
  bool _isVerified = false;
  final double _targetValue = 0.8; // Target is around 80% of the slider
  final double _tolerance = 0.05;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 80, color: Colors.pinkAccent),
              const SizedBox(height: 20),
              Text(
                "captcha_title".tr(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "captcha_subtitle".tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 50),
              // Simple "Fit the Piece" visual representation
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  Container(
                    height: 50,
                    width:
                        MediaQuery.of(context).size.width *
                        0.8 *
                        _targetValue, // Visual target indicator
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 4,
                      height: 50,
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.pinkAccent,
                      inactiveTrackColor: Colors.transparent,
                      thumbColor: Colors.pink,
                      overlayColor: Colors.pink.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: _sliderValue,
                      onChanged: (value) {
                        setState(() {
                          _sliderValue = value;
                        });
                      },
                      onChangeEnd: (value) {
                        if ((value - _targetValue).abs() < _tolerance) {
                          setState(() {
                            _isVerified = true;
                          });
                          Future.delayed(
                            const Duration(milliseconds: 500),
                            () async {
                              if (mounted) {
                                // Save user details locally
                                await context.read<AuthCubit>().saveUserDetails(
                                  name: widget.name,
                                  surname: widget.surname,
                                  dob: widget.dob,
                                  profilePicPath:
                                      "", // Empty initially, set in SetupPage
                                );
                                if (mounted) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SetupPage(),
                                    ),
                                    (route) => false,
                                  );
                                }
                              }
                            },
                          );
                        } else {
                          setState(() {
                            _sliderValue = 0.0;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("captcha_failed".tr())),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_isVerified)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      "captcha_verified".tr(),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              else
                Text("captcha_instruction".tr()),
            ],
          ),
        ),
      ),
    );
  }
}
