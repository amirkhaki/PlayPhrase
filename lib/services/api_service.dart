import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/phrase.dart';

class ApiService {
  static const String _baseUrl = 'https://www.playphrase.me/api/v1/phrases/search';
  static const String _previewUrl = 'https://www.playphrase.me/api/v1/phrases/all-previews';
  static const String _videoBaseUrl = 'https://s3.eu-central-1.wasabisys.com/video-eu.playphrase.me/english-storage';
  static const String _csrfToken = 'cmf6ALYjeK3Xxi1Wobc1dIitdPqz+IjROylUqKHePZ+HQCkfROzIedaKmgSWlbgJogBBpd5HpkcmvFLF';
  
  static final Map<String, SearchResponse> _searchCache = {};
  static final Map<String, List<String>> _previewCache = {};
  static final Map<String, String> _videoCache = {};

  static Map<String, String> get _headers => {
    'accept': 'json',
    'authorization': 'Token',
    'content-type': 'json',
    'referer': 'https://www.playphrase.me/',
    'x-csrf-token': _csrfToken,
  };

  static Future<SearchResponse> searchPhrases(String query, {int limit = 5}) async {
    final cacheKey = '$query-$limit';
    if (_searchCache.containsKey(cacheKey)) {
      return _searchCache[cacheKey]!;
    }

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'q': query,
      'limit': limit.toString(),
      'language': 'en',
      'platform': 'desktop safari',
      'skip': '0',
    });

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final result = SearchResponse.fromJson(data);
      _searchCache[cacheKey] = result;
      return result;
    } else {
      throw Exception('Failed to search phrases: ${response.statusCode}');
    }
  }

  static Future<List<String>> getPreviewVideoUrls(String query) async {
    if (_previewCache.containsKey(query)) {
      return _previewCache[query]!;
    }

    final uri = Uri.parse(_previewUrl).replace(queryParameters: {
      'q': query,
      'language': 'en',
      'actor-id': '',
    });

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> previews = json.decode(response.body);
      final videoUrls = previews.map((previewUrl) {
        return _convertPreviewToVideoUrl(previewUrl as String);
      }).toList();
      _previewCache[query] = videoUrls;
      return videoUrls;
    } else {
      throw Exception('Failed to get previews: ${response.statusCode}');
    }
  }

  static String _convertPreviewToVideoUrl(String previewUrl) {
    // Extract ID from: https://www.playphrase.me/video/eng/preview/670b495d.../6721f2d4....png
    // Convert to: https://s3.eu-central-1.wasabisys.com/video-eu.playphrase.me/english-storage/670b495d.../6721f2d4....mp4
    final regex = RegExp(r'/preview/([^/]+/[^.]+)\.png');
    final match = regex.firstMatch(previewUrl);
    if (match != null) {
      final id = match.group(1);
      return '$_videoBaseUrl/$id.mp4';
    }
    return previewUrl;
  }

  static Future<String> getCachedVideoPath(String videoUrl) async {
    if (_videoCache.containsKey(videoUrl)) {
      final path = _videoCache[videoUrl]!;
      if (!kIsWeb && await File(path).exists()) {
        return path;
      }
    }

    if (kIsWeb) {
      return videoUrl;
    }

    final dir = await getApplicationCacheDirectory();
    final videoDir = Directory('${dir.path}/videos');
    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
    }

    final fileName = videoUrl.split('/').last;
    final filePath = '${videoDir.path}/$fileName';
    final file = File(filePath);

    if (await file.exists()) {
      _videoCache[videoUrl] = filePath;
      return filePath;
    }

    final response = await http.get(Uri.parse(videoUrl));
    if (response.statusCode == 200) {
      await file.writeAsBytes(response.bodyBytes);
      _videoCache[videoUrl] = filePath;
      return filePath;
    }

    return videoUrl;
  }

  static void clearCache() {
    _searchCache.clear();
    _previewCache.clear();
    _videoCache.clear();
  }
}
