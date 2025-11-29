import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: _MinimalLoaderBackground());
  }
}

class _MinimalLoaderBackground extends StatelessWidget {
  const _MinimalLoaderBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color.fromARGB(255, 255, 226, 236), Colors.white],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 55,
          height: 55,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(
              Color.fromARGB(255, 255, 160, 190),
            ),
          ),
        ),
      ),
    );
  }
}
