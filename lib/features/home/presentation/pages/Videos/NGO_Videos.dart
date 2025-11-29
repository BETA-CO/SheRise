import 'package:flutter/material.dart';

class NgoVideosPage extends StatefulWidget {
  const NgoVideosPage({super.key});

  @override
  State<NgoVideosPage> createState() => NgoVideosPageState();
}

class NgoVideosPageState extends State<NgoVideosPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("NGO Seminaars")),
      body: const Center(child: Text("NGO Seminaar Page")),
    );
  }
}