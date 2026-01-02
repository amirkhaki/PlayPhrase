import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/phrase.dart';
import '../services/api_service.dart';
import 'subtitle_overlay.dart';

class VideoPlayerWidget extends StatefulWidget {
  final List<VideoItem> videos;
  final String searchQuery;
  final VoidCallback? onAllVideosCompleted;

  const VideoPlayerWidget({
    super.key,
    required this.videos,
    required this.searchQuery,
    this.onAllVideosCompleted,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late final Player _player;
  late final VideoController _controller;
  int _currentIndex = 0;
  bool _isLoading = true;
  Duration _currentPosition = Duration.zero;
  String _currentSubtitle = '';
  final Set<int> _preloadedIndices = {};

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    
    _player.stream.position.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });
    
    _player.stream.subtitle.listen((subtitle) {
      if (mounted) {
        setState(() {
          _currentSubtitle = subtitle.join('\n');
        });
      }
    });
    
    _player.stream.completed.listen((completed) {
      if (completed) {
        _playNext();
      }
    });
    
    if (widget.videos.isNotEmpty) {
      _initializeVideo(_currentIndex);
    }
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.videos != oldWidget.videos) {
      _currentIndex = 0;
      _preloadedIndices.clear();
      if (widget.videos.isNotEmpty) {
        _initializeVideo(0);
      }
    }
  }

  Future<void> _preloadVideos(int currentIndex) async {
    // Preload next 2 videos
    for (int i = 1; i <= 2; i++) {
      final preloadIndex = currentIndex + i;
      if (preloadIndex < widget.videos.length && !_preloadedIndices.contains(preloadIndex)) {
        _preloadedIndices.add(preloadIndex);
        final video = widget.videos[preloadIndex];
        // Just cache the video file, don't play it
        ApiService.getCachedVideoPath(video.videoUrl);
      }
    }
  }

  Future<void> _initializeVideo(int index) async {
    if (index >= widget.videos.length) {
      widget.onAllVideosCompleted?.call();
      return;
    }

    setState(() {
      _isLoading = true;
      _currentSubtitle = '';
    });

    final video = widget.videos[index];
    
    try {
      final videoPath = await ApiService.getCachedVideoPath(video.videoUrl);
      
      Media media;
      if (kIsWeb || videoPath.startsWith('http')) {
        media = Media(video.videoUrl);
      } else {
        media = Media('file://$videoPath');
      }

      await _player.open(media);
      
      // Select the subtitle track (index 0 is usually the first subtitle track)
      // Wait a bit for tracks to be detected
      await Future.delayed(const Duration(milliseconds: 200));
      final tracks = _player.state.tracks.subtitle;
      if (tracks.isNotEmpty) {
        await _player.setSubtitleTrack(tracks.first);
      }
      
      // Start preloading next videos
      _preloadVideos(index);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading video: $e')),
        );
      }
    }
  }

  void _playNext() {
    if (_currentIndex < widget.videos.length - 1) {
      _currentIndex++;
      _initializeVideo(_currentIndex);
    } else {
      widget.onAllVideosCompleted?.call();
    }
  }

  void _playPrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _initializeVideo(_currentIndex);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Widget _buildCustomControls(VideoState state) {
    return Stack(
      children: [
        // Tap to play/pause
        Positioned.fill(
          child: GestureDetector(
            onTap: _player.playOrPause,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Bottom controls
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bar
                StreamBuilder<Duration>(
                  stream: _player.stream.position,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = _player.state.duration;
                    final maxMs = duration.inMilliseconds.toDouble().clamp(1.0, double.infinity);
                    final valueMs = position.inMilliseconds.toDouble().clamp(0.0, maxMs);
                    return SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: valueMs.toDouble(),
                        max: maxMs.toDouble(),
                        onChanged: (value) {
                          _player.seek(Duration(milliseconds: value.toInt()));
                        },
                        activeColor: Colors.white,
                        inactiveColor: Colors.white24,
                      ),
                    );
                  },
                ),
                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.skip_previous,
                        color: _currentIndex > 0 ? Colors.white : Colors.white38,
                      ),
                      onPressed: _currentIndex > 0 ? _playPrevious : null,
                    ),
                    StreamBuilder<bool>(
                      stream: _player.stream.playing,
                      builder: (context, snapshot) {
                        final playing = snapshot.data ?? false;
                        return IconButton(
                          icon: Icon(
                            playing ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: _player.playOrPause,
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.skip_next,
                        color: _currentIndex < widget.videos.length - 1 
                            ? Colors.white 
                            : Colors.white38,
                      ),
                      onPressed: _currentIndex < widget.videos.length - 1 ? _playNext : null,
                    ),
                    const Spacer(),
                    Text(
                      '${_currentIndex + 1}/${widget.videos.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videos.isEmpty) {
      return const Center(
        child: Text(
          'Enter a phrase to search',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    final currentVideo = widget.videos[_currentIndex];

    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Video(
                  controller: _controller,
                  controls: _buildCustomControls,
                  subtitleViewConfiguration: const SubtitleViewConfiguration(visible: false),
                ),
              
              if (!_isLoading && currentVideo.hasWordTiming)
                Positioned(
                  bottom: 100,
                  left: 20,
                  right: 20,
                  child: IgnorePointer(
                    child: SubtitleOverlay(
                      phrase: currentVideo.phrase!,
                      currentPosition: _currentPosition,
                    ),
                  ),
                ),
              
              // Show embedded subtitle overlay for videos without phrase data
              if (!_isLoading && !currentVideo.hasWordTiming && _currentSubtitle.isNotEmpty)
                Positioned(
                  bottom: 100,
                  left: 20,
                  right: 20,
                  child: IgnorePointer(
                    child: EmbeddedSubtitleOverlay(
                      subtitleText: _currentSubtitle,
                      searchQuery: widget.searchQuery,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        _buildVideoInfo(),
      ],
    );
  }

  Widget _buildVideoInfo() {
    if (widget.videos.isEmpty) return const SizedBox.shrink();
    
    final video = widget.videos[_currentIndex];
    final info = video.info;
    if (info == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        info,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }
}
