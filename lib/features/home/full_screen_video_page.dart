import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/app_colors.dart';

class FullScreenVideoPage extends StatefulWidget {
  final String videoUrl;
  const FullScreenVideoPage({super.key, required this.videoUrl});

  @override
  State<FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<FullScreenVideoPage> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  bool _isDragging = false;
  Timer? _hideTimer;
  bool _isEnded = false; // New variable to track end state smoothly

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(false);
        _playVideo();
      });

    _controller.addListener(_videoListener);
  }

  void _videoListener() {
    if (!_controller.value.isInitialized || _isDragging) return;

    // Check if video ended with a small buffer to catch it reliably
    final bool isEnded =
        _controller.value.position >= _controller.value.duration;

    if (isEnded && !_isEnded) {
      // Video Just Ended
      setState(() {
        _isEnded = true;
        _showControls = true; // Force show controls smoothly
      });
      _hideTimer?.cancel();
    } else if (!isEnded && _isEnded) {
      // Video Reset
      setState(() {
        _isEnded = false;
      });
    }

    // Update UI for slider smoothness
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  // --- ACTIONS ---

  void _playVideo() {
    _controller.play();
    _startHideTimer();
    setState(() => _showControls = true);
  }

  void _pauseVideo() {
    _controller.pause();
    _hideTimer?.cancel();
    setState(() => _showControls = true);
  }

  // FIXED: Smooth Replay Logic
  Future<void> _replayVideo() async {
    // 1. Pause first to prevent stutter
    _controller.pause();

    // 2. Wait for seek to complete (Crucial for smoothness)
    await _controller.seekTo(Duration.zero);

    setState(() {
      _isEnded = false;
    });

    // 3. Play
    _playVideo();

    // 4. Hide controls after a short delay for immersion
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && _controller.value.isPlaying) {
        _startHideTimer();
      }
    });
  }

  void _togglePlay() {
    if (_isEnded) {
      _replayVideo();
    } else if (_controller.value.isPlaying) {
      _pauseVideo();
    } else {
      _playVideo();
    }
  }

  void _onScreenTap() {
    setState(() => _showControls = !_showControls);
    if (_showControls && _controller.value.isPlaying && !_isEnded) {
      _startHideTimer();
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying && !_isDragging) {
        setState(() => _showControls = false);
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onScreenTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. VIDEO
            Center(
              child: _controller.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : const CircularProgressIndicator(color: AppColors.primary),
            ),

            // 2. CONTROLS OVERLAY
            IgnorePointer(
              ignoring: !_showControls,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250), // Smooth Fade
                child: Container(
                  color: Colors.black38,
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top: Close
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.white, size: 30),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),

                        // Center: Animated Play/Pause/Replay Icon
                        GestureDetector(
                          onTap: _togglePlay,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: Icon(
                              _isEnded
                                  ? Icons.replay_circle_filled
                                  : (_controller.value.isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_fill),
                              key: ValueKey(_isEnded
                                  ? "replay"
                                  : (_controller.value.isPlaying
                                      ? "pause"
                                      : "play")),
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        // Bottom: Seek Bar
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              Text(_formatDuration(_controller.value.position),
                                  style: const TextStyle(color: Colors.white)),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    thumbColor: AppColors.primary,
                                    activeTrackColor: AppColors.primary,
                                    inactiveTrackColor: Colors.white24,
                                    thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 8),
                                    overlayShape: const RoundSliderOverlayShape(
                                        overlayRadius: 16),
                                  ),
                                  child: Slider(
                                    min: 0,
                                    max: _controller.value.duration.inSeconds
                                        .toDouble(),
                                    value: _controller.value.position.inSeconds
                                        .toDouble()
                                        .clamp(
                                            0,
                                            _controller.value.duration.inSeconds
                                                .toDouble()),
                                    onChangeStart: (_) {
                                      _isDragging = true;
                                      _hideTimer?.cancel();
                                    },
                                    onChangeEnd: (value) async {
                                      _isDragging = false;
                                      await _controller.seekTo(
                                          Duration(seconds: value.toInt()));
                                      if (_controller.value.position <
                                          _controller.value.duration) {
                                        _playVideo();
                                      }
                                    },
                                    onChanged: (value) => setState(() {}),
                                  ),
                                ),
                              ),
                              Text(_formatDuration(_controller.value.duration),
                                  style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
