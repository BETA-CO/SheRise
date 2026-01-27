import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sherise/features/wellness/breathing_game.dart';
import 'package:sherise/features/wellness/bubble_pop_game.dart';
import 'package:sherise/features/wellness/zen_garden_game.dart';
import 'package:sherise/features/wellness/particle_flow_game.dart';
import 'package:sherise/features/wellness/fidget_board_game.dart';
import 'package:sherise/features/wellness/fireworks_game.dart';

class WellnessPage extends StatelessWidget {
  const WellnessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("wellness_title".tr()), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "wellness_subtitle".tr(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            _buildGameCard(
              context,
              title: "game_breathing".tr(),
              description: "desc_breathing".tr(),
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
              title: "game_bubble".tr(),
              description: "desc_bubble".tr(),
              icon: Icons.circle_outlined,
              color: Colors.pinkAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BubblePopGame()),
              ),
            ),
            const SizedBox(height: 20),
            _buildGameCard(
              context,
              title: "game_zen".tr(),
              description: "desc_zen".tr(),
              icon: Icons.landscape,
              color: const Color(0xFF8D6E63),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ZenGardenGame()),
              ),
            ),
            const SizedBox(height: 20),
            _buildGameCard(
              context,
              title: "game_ink".tr(),
              description: "desc_ink".tr(),
              icon: Icons.water_drop,
              color: Colors.cyan,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ParticleFlowGame(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildGameCard(
              context,
              title: "game_fidget".tr(),
              description: "desc_fidget".tr(),
              icon: Icons.toggle_on,
              color: Colors.grey,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FidgetBoardGame(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildGameCard(
              context,
              title: "game_bursts".tr(),
              description: "desc_bursts".tr(),
              icon: Icons.auto_awesome,
              color: Colors.purpleAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FireworksGame()),
              ),
            ),
            const SizedBox(height: 20),
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
                  color: color.withValues(alpha: 0.2),
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
