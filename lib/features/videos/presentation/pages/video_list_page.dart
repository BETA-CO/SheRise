import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sherise/features/videos/data/video_model.dart';
import 'package:sherise/features/videos/data/video_repository.dart';
import 'package:sherise/features/videos/data/video_download_service.dart';
import 'package:sherise/features/videos/presentation/pages/video_player_page.dart';
import 'package:path_provider/path_provider.dart';

class VideoListPage extends StatefulWidget {
  final String category;
  const VideoListPage({super.key, required this.category});

  @override
  State<VideoListPage> createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage> {
  final VideoRepository _repository = VideoRepository();
  final VideoDownloadService _downloadService = VideoDownloadService();
  final Set<String> _downloadedVideoIds = {};
  final Map<String, double> _downloadProgress = {};

  late Future<List<Video>> _videosFuture;

  @override
  void initState() {
    super.initState();
    // Fetch all, then filter
    _videosFuture = _repository.getVideos().then((list) async {
      final filtered = list
          .where((v) => v.category == widget.category)
          .toList();
      for (final v in filtered) {
        if (await _downloadService.isVideoDownloaded(v.id)) {
          if (mounted) {
            setState(() {
              _downloadedVideoIds.add(v.id);
            });
          }
        }
      }
      return filtered;
    });
  }

  void _onVideoTap(Video video) async {
    // Check if downloaded
    final isDownloaded = await _downloadService.isVideoDownloaded(video.id);

    if (isDownloaded) {
      if (!mounted) return;
      _navigateToPlayer(video);
    } else {
      if (_downloadProgress.containsKey(video.id)) {
        return; // Already downloading
      }
      _startDownload(video);
    }
  }

  void _navigateToPlayer(Video video) async {
    // Check for file existence again (optional but good practice)
    final isDownloaded = await _downloadService.isVideoDownloaded(video.id);

    // If we are navigating, we assume it's downloaded.
    // We construct the path manually or get it.
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/${video.id}.mp4';

    if (isDownloaded) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              VideoPlayerPage(videoPath: path, videoTitle: video.title),
        ),
      );
    }
  }

  void _startDownload(Video video) async {
    setState(() {
      _downloadProgress[video.id] = 0.0;
    });

    try {
      await _downloadService.downloadVideo(
        video.downloadUrl,
        video.id,
        (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress[video.id] = progress;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _downloadedVideoIds.add(video.id);
          _downloadProgress.remove(video.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('msg_download_complete'.tr(args: [video.title])),
            backgroundColor: const Color(0xFF00695C),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadProgress.remove(video.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('err_download_failed'.tr(args: [e.toString()])),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteVideo(Video video) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_video_title'.tr()),
        content: Text('delete_video_prompt'.tr(args: [video.title])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr(), style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('delete'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _downloadService.deleteVideo(video.id);
        if (mounted) {
          setState(() {
            _downloadedVideoIds.remove(video.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('msg_video_deleted'.tr())),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('err_download_failed'.tr(args: [e.toString()])), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.category == 'NGO Seminars' ? 'ngo_seminars_title'.tr() : 
          widget.category == 'Health Awareness' ? 'health_awareness'.tr() :
          widget.category == 'Self Defence' ? 'self_defence'.tr() :
          widget.category == 'Cancer Awareness' ? 'cancer_awareness'.tr() :
          widget.category,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
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
          child: FutureBuilder<List<Video>>(
            future: _videosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00695C)),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "err_load_videos".tr(),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _videosFuture = _repository.getVideos().then((
                              list,
                            ) {
                              return list
                                  .where((v) => v.category == widget.category)
                                  .toList();
                            });
                          });
                        },
                        child: Text(
                          "btn_retry".tr(),
                          style: const TextStyle(color: Color(0xFF00695C)),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final videos = snapshot.data ?? [];
              if (videos.isEmpty) {
                return Center(
                  child: Text(
                    "no_videos".tr(),
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: videos.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final video = videos[index];
                  return _buildModernVideoCard(video);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildModernVideoCard(Video video) {
    final bool isDownloaded = _downloadedVideoIds.contains(video.id);
    final double? progress = _downloadProgress[video.id];
    final bool isDownloading = progress != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 0.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00695C).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _onVideoTap(video),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Area
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.grey[200],
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (video.thumbUrl.isNotEmpty)
                        Image.network(
                          video.thumbUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (c, o, s) => const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      // Play Button Overlay
                      Center(
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00695C).withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      // Progress Overlay
                      if (isDownloading)
                        Container(
                          color: Colors.black26,
                          child: Center(
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(
                                value: progress > 0 ? progress : null,
                                color: Colors.white,
                                strokeWidth: 4,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Info Area
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatDate(video.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Action Icons
                  if (isDownloading)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF00695C),
                        ),
                      ),
                    )
                  else if (isDownloaded)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteVideo(video),
                      tooltip: 'Delete Video',
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.download_rounded,
                          color: Color(0xFF00695C)),
                      onPressed: () => _onVideoTap(video),
                      tooltip: 'Download Video',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return "recently_added".tr();
    try {
      final date = DateTime.parse(dateStr);
      // Simple custom format: "Jan 15, 2026"
      const months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec",
      ];
      return "${months[date.month - 1]} ${date.day}, ${date.year}";
    } catch (_) {
      return "recently_added".tr();
    }
  }
}
