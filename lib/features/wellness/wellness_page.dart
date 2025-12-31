import 'package:flutter/material.dart';
import 'package:sherise/features/wellness/breathing_game.dart';
import 'package:sherise/features/wellness/bubble_pop_game.dart';

class WellnessPage extends StatelessWidget {
  const WellnessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mental Wellness"), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Take a moment for yourself.",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            _buildGameCard(
              context,
              title: "Breathing Exercise",
              description: "Calm your mind with guided breathing.",
              icon: Icons.air,
              color: Colors.blueAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BreathingGame()),
              ),
            ),
            const SizedBox(height: 20),
            _buildGameCard(
              context,
              title: "Bubble Pop",
              description: "Relieve stress by popping bubbles.",
              icon: Icons.circle_outlined,
              color: Colors.pinkAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BubblePopGame()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
