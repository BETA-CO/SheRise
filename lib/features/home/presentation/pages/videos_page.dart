import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'Videos/ngo_videos.dart';
import 'Videos/health_videos.dart';
import 'Videos/SelfDefence_Videos.dart';
import 'Videos/cancer_awareness.dart';

class VideosPage extends StatefulWidget {
  const VideosPage({super.key});

  @override
  State<VideosPage> createState() => _VideosPageState();
}

class _VideosPageState extends State<VideosPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromARGB(255, 255, 236, 242), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(
                      'videos'.tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ScrollConfiguration(
                  behavior: const _BouncyScrollBehavior(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildVideoCard(
                          title: 'ngo_seminars'.tr(),
                          gradientColors: [
                            Colors.pinkAccent.withValues(alpha: 0.35),
                            Colors.white,
                          ],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NgoVideosPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildVideoCard(
                          title: 'health_awareness'.tr(),
                          gradientColors: [
                            Colors.teal.withValues(alpha: 0.35),
                            Colors.white,
                          ],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const HealthAwarenessPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildVideoCard(
                          title: 'self_defence'.tr(),
                          gradientColors: [
                            Colors.orangeAccent.withValues(alpha: 0.35),
                            Colors.white,
                          ],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SelfDefencePage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildVideoCard(
                          title: 'cancer_awareness'.tr(),
                          gradientColors: [
                            Colors.purpleAccent.withValues(alpha: 0.35),
                            Colors.white,
                          ],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CancerAwareness(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoCard({
    required String title,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 6,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: gradientColors,
              stops: const [0.1, 1.0],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.image_outlined,
                    color: Colors.black38,
                    size: 40,
                  ),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BouncyScrollBehavior extends ScrollBehavior {
  const _BouncyScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}
