import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class VideoDownloadService {
  final Dio _dio = Dio();

  Future<String> downloadVideo(
    String url,
    String fileName,
    Function(double) onProgress,
  ) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName.mp4';
      final file = File(filePath);

      if (await file.exists()) {
        return filePath; // Already downloaded
      }

      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );

      return filePath;
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }

  Future<bool> isVideoDownloaded(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName.mp4');
    return file.exists();
  }
}
