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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "wellness_title".tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "wellness_subtitle".tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                _buildGameCard(
                  context,
                  title: "game_breathing".tr(),
                  description: "desc_breathing".tr(),
                  icon: Icons.air,
                  color: const Color(0xFF00695C),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BreathingGame(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: "game_bubble".tr(),
                  description: "desc_bubble".tr(),
                  icon: Icons.circle_outlined,
                  color: const Color(0xFF00695C),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BubblePopGame(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: "game_zen".tr(),
                  description: "desc_zen".tr(),
                  icon: Icons.landscape,
                  color: const Color(0xFF00695C),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ZenGardenGame(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: "game_ink".tr(),
                  description: "desc_ink".tr(),
                  icon: Icons.water_drop,
                  color: const Color(0xFF00695C),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ParticleFlowGame(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: "game_fidget".tr(),
                  description: "desc_fidget".tr(),
                  icon: Icons.toggle_on,
                  color: const Color(0xFF00695C),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FidgetBoardGame(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: "game_bursts".tr(),
                  description: "desc_bursts".tr(),
                  icon: Icons.auto_awesome,
                  color: const Color(0xFF00695C),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FireworksGame(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2FCF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 0.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00695C).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 28, color: color),
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
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF00695C),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
