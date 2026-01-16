import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sherise/features/videos/data/video_model.dart';
import 'dart:developer' as dev;

class VideoRepository {
  final Dio _dio = Dio();
  static const String _storageKey = 'cached_video_list';

  // TODO: Replace with your Google Apps Script Web App URL
  static const String _jsonUrl =
      'https://script.google.com/macros/s/AKfycbwuuA0a4doAd7N5KgIDz3CC_sP4kdc5EYUHnXFpenTYok7kJf8uhuLJtCelenLTQmOj8w/exec';

  Future<List<Video>> getVideos() async {
    if (_jsonUrl.contains('REPLACE')) {
      return []; // Return empty if not configured
    }

    try {
      final response = await _dio.get(_jsonUrl);

      if (response.statusCode == 200) {
        final data = response.data;

        List<dynamic> list;
        if (data is List) {
          list = data;
        } else if (data is Map && data.containsKey('record')) {
          // Handle JSONBin.io structure
          list = data['record'];
        } else {
          list = [];
        }

        // Cache the valid data
        _cacheData(list);

        return list.map((e) => Video.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load videos from network');
      }
    } catch (e) {
      dev.log("Network error, attempting to load from cache: $e");
      // Fallback to cache
      final cachedList = await _loadFromCache();
      if (cachedList != null) {
        return cachedList.map((e) => Video.fromJson(e)).toList();
      }
      // If no cache, rethrow
      throw Exception('Error fetching videos and no cache available: $e');
    }
  }

  Future<void> _cacheData(List<dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(data);
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      dev.log("Error caching video data: $e");
    }
  }

  Future<List<dynamic>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        return jsonDecode(jsonString);
      }
    } catch (e) {
      dev.log("Error loading cached video data: $e");
    }
    return null;
  }
}
