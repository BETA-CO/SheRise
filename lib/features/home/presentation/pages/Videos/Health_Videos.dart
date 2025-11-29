import 'package:flutter/material.dart';

class HealthAwarenessPage extends StatefulWidget {
  const HealthAwarenessPage({super.key});

  @override
  State<HealthAwarenessPage> createState() => _HealthAwarenessPageState();
}

class _HealthAwarenessPageState extends State<HealthAwarenessPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Health Awareness")),
      body: const Center(child: Text("Health Awareness Page")),
    );
  }
}