import 'package:flutter/material.dart';

class CancerAwareness extends StatefulWidget {
  const CancerAwareness({super.key});

  @override
  State<CancerAwareness> createState() => _CancerAwarenessState();
}

class _CancerAwarenessState extends State<CancerAwareness> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cancer Awareness")),
      body: const Center(child: Text("Cancer Awareness Page")),
    );
  }
}
