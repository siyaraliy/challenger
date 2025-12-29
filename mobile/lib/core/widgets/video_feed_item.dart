import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'video_player_widget.dart';

class VideoFeedItem extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;

  const VideoFeedItem({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
  });

  @override
  State<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends State<VideoFeedItem> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
          _controller.setVolume(0); // Start muted
          _controller.setLooping(true); // Loop
          if (_isVisible) {
            _controller.play();
          }
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;
    
    final visiblePercentage = info.visibleFraction * 100;
    final isVisible = visiblePercentage > 60; // Play when 60% visible

    if (isVisible != _isVisible) {
      if (mounted) {
        setState(() => _isVisible = isVisible);
        if (_isInitialized) {
          if (isVisible) {
            _controller.play();
          } else {
            _controller.pause();
          }
        }
      }
    }
  }

  void _openFullScreen() {
    _controller.pause(); // Pause feed video
    VideoPlayerDialog.show(
      context,
      widget.videoUrl,
      thumbnailUrl: widget.thumbnailUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.videoUrl),
      onVisibilityChanged: _handleVisibilityChanged,
      child: GestureDetector(
        onTap: _openFullScreen,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 300),
          width: double.infinity,
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Thumbnail (if not initialized)
              if (!_isInitialized && widget.thumbnailUrl != null)
                Image.network(
                  widget.thumbnailUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),

              // 2. Video Player
              if (_isInitialized)
                AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),

              // 3. Loading Indicator
              if (!_isInitialized && widget.thumbnailUrl == null)
                const CircularProgressIndicator(),

              // 4. Mute Icon / Hint
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.volume_off, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
