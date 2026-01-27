import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:path_provider/path_provider.dart';

class FileAssetLoader extends AssetLoader {
  const FileAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    final languageCode = locale.languageCode;
    // Always use bundle for English as requested
    if (languageCode == 'en') {
      return await _loadFromBundle(path, locale);
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final localFile = File('${appDir.path}/lang/$languageCode.json');

      if (await localFile.exists()) {
        final content = await localFile.readAsString();
        return json.decode(content);
      }

      // Check Temporary Cache (Online Session)
      final tempDir = await getTemporaryDirectory();
      final cachedFile = File('${tempDir.path}/lang_cache/$languageCode.json');
      if (await cachedFile.exists()) {
        final content = await cachedFile.readAsString();
        return json.decode(content);
      }
    } catch (e) {
      // Sshh
    }

    // For non-English, if local fails, we could try bundle, but since we deleted them,
    // it will return empty. Safety fallback to strictly return empty or let easy_localization handle it.
    return {};
  }

  Future<Map<String, dynamic>> _loadFromBundle(
    String path,
    Locale locale,
  ) async {
    final assetPath = '$path/${locale.languageCode}.json';
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      return json.decode(jsonString);
    } catch (e) {
      debugPrint('Error loading bundle asset: $e');
      return {};
    }
  }
}
