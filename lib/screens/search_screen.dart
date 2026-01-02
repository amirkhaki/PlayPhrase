import 'package:flutter/material.dart';
import '../models/phrase.dart';
import '../services/api_service.dart';
import '../widgets/video_player_widget.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<VideoItem> _videos = [];
  String _lastQuery = '';
  bool _isLoading = false;
  String? _error;

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _lastQuery = query;
    });

    try {
      // Fetch both APIs in parallel
      final results = await Future.wait([
        ApiService.searchPhrases(query),
        ApiService.getPreviewVideoUrls(query),
      ]);

      final searchResponse = results[0] as SearchResponse;
      final previewUrls = results[1] as List<String>;

      // Get video URLs from main API to filter duplicates
      final mainVideoUrls = searchResponse.phrases.map((p) => p.videoUrl).toSet();

      // Create video items from phrases (with word timing)
      final phraseVideos = searchResponse.phrases.map((p) => VideoItem.fromPhrase(p)).toList();

      // Create video items from preview URLs (without word timing), filtering out duplicates
      final previewVideos = previewUrls
          .where((url) => !mainVideoUrls.contains(url))
          .map((url) => VideoItem.fromUrl(url))
          .toList();

      setState(() {
        _videos = [...phraseVideos, ...previewVideos];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PlayPhrase'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Enter a phrase to search...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _search,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Search'),
                ),
              ],
            ),
          ),
          
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          
          Expanded(
            child: VideoPlayerWidget(
              videos: _videos,
              searchQuery: _lastQuery,
              onAllVideosCompleted: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All videos completed!')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
