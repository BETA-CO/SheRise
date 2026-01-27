import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LocalizationService {
  final Dio _dio = Dio();
  static const String _baseUrl =
      'https://raw.githubusercontent.com/BETA-CO/language-testing/refs/heads/main';

  // Singleton instance
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  /// Downloads language to Temporary cache (for immediate online use).
  Future<String> downloadToTemp(String languageCode) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final langDir = Directory('${tempDir.path}/lang_cache');
      if (!await langDir.exists()) {
        await langDir.create(recursive: true);
      }

      final fileName = '$languageCode.json';
      final savePath = '${langDir.path}/$fileName';
      final downloadUrl = '$_baseUrl/$fileName';

      await _dio.download(downloadUrl, savePath);
      return savePath;
    } catch (e) {
      rethrow;
    }
  }

  /// Moves cached file to Persistent storage (for offline use).
  /// If not in cache, downloads fresh.
  Future<void> makePermanent(String languageCode) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final permDir = Directory('${appDir.path}/lang');
      if (!await permDir.exists()) {
        await permDir.create(recursive: true);
      }
      final permPath = '${permDir.path}/$languageCode.json';

      // Check cache first
      final tempDir = await getTemporaryDirectory();
      final cachedFile = File('${tempDir.path}/lang_cache/$languageCode.json');

      if (await cachedFile.exists()) {
        await cachedFile.copy(permPath);
      } else {
        // Download directly if not cached
        final downloadUrl = '$_baseUrl/$languageCode.json';
        await _dio.download(downloadUrl, permPath);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isPersistent(String languageCode) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/lang/$languageCode.json');
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Legacy alias for compatibility
  Future<bool> isLanguageDownloaded(String languageCode) =>
      isPersistent(languageCode);

  Future<void> deleteLocalLanguage(String languageCode) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/lang/$languageCode.json');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ssshh
    }
  }
}
