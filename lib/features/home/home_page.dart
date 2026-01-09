import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart'; // REQUIRED for Auto-Play
import '../../core/theme/app_colors.dart';
import '../../widgets/loading_indicator.dart';
import '../providers.dart';
import 'create_post_page.dart';
import 'full_screen_video_page.dart';

// --- ADMIN CHECK PROVIDER ---
final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return false;

  // Check 'is_admin' column in profiles table
  final data = await Supabase.instance.client
      .from('profiles')
      .select('is_admin')
      .eq('id', user.id)
      .maybeSingle();

  return data != null && data['is_admin'] == true;
});

// --- HOME PAGE WIDGET ---
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch Realtime Streams
    final postsAsync = ref.watch(postsProvider);
    final isAdminAsync = ref.watch(isAdminProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // Light grey background

      // 1. App Bar
      appBar: AppBar(
        title: const Text(
          "T Kairos",
          style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold),
        ),
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
      ),

      // 2. Admin Floating Action Button
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: isAdminAsync.when(
        data: (isAdmin) => isAdmin
            ? Padding(
                // Padding ensures it sits ABOVE the Glass Bottom Bar
                padding: const EdgeInsets.only(bottom: 90.0),
                child: FloatingActionButton(
                  backgroundColor: AppColors.primary,
                  elevation: 4,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CreatePostPage())),
                ),
              )
            : null,
        error: (_, __) => null,
        loading: () => null,
      ),

      // 3. Post Feed
      body: postsAsync.when(
        data: (data) {
          if (data.isEmpty) return const Center(child: Text("No posts yet."));

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(postsProvider),
            color: AppColors.primary,
            child: ListView.separated(
              // Bottom padding ensures last post isn't hidden by nav bar
              padding: const EdgeInsets.only(bottom: 120),
              itemCount: data.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final post = data[index];
                // Pass unique Key based on ID for VisibilityDetector
                return PostItem(key: Key(post['id'].toString()), post: post);
              },
            ),
          );
        },
        error: (e, st) => Center(child: Text('Error loading feed')),
        loading: () => const SakuraLoading(),
      ),
    );
  }
}

// --- SINGLE POST ITEM (Handles Video Logic) ---
class PostItem extends StatefulWidget {
  final Map<String, dynamic> post;
  const PostItem({super.key, required this.post});

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  bool _isMuted = true; // Videos start muted by default

  @override
  void initState() {
    super.initState();
    final url = widget.post['image_url'];
    final type = widget.post['media_type'];

    if (url != null && type == 'video') {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _videoController!.setVolume(0.0); // Start Muted
            _videoController!.setLooping(true); // Loop preview
            // NOTE: We do NOT call play() here.
            // VisibilityDetector handles auto-play.
          }
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  // Open Full Screen Player
  void _openFullScreen() {
    if (_videoController == null) return;

    _videoController!.pause(); // Pause preview
    setState(() => _isPlaying = false);

    Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    FullScreenVideoPage(videoUrl: widget.post['image_url'])))
        .then((_) {
      // Resume preview when returning
      if (mounted && _videoController != null) {
        _videoController!.play();
        setState(() => _isPlaying = true);
      }
    });
  }

  // Toggle Mute/Unmute
  void _toggleMute() {
    if (_videoController == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final String? mediaUrl = widget.post['image_url'];
    final String? mediaType = widget.post['media_type'];
    final String? content = widget.post['content'];
    final int likes = widget.post['likes'] ?? 0;

    // Wraps content to detect if it's on screen
    return VisibilityDetector(
      key: widget.key!,
      onVisibilityChanged: (info) {
        if (_videoController == null || !_videoController!.value.isInitialized)
          return;

        // AUTO PLAY LOGIC: If > 60% of video is visible, Play. Else Pause.
        if (info.visibleFraction > 0.6) {
          if (!_videoController!.value.isPlaying) {
            _videoController!.play();
            setState(() => _isPlaying = true);
          }
        } else {
          if (_videoController!.value.isPlaying) {
            _videoController!.pause();
            setState(() => _isPlaying = false);
          }
        }
      },
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.secondary,
                    child: Icon(Icons.person, size: 16, color: Colors.white),
                  ),
                  SizedBox(width: 10),
                  Text("T Kairos Official",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Spacer(),
                  Icon(Icons.more_horiz, color: Colors.grey),
                ],
              ),
            ),

            // MEDIA AREA (Image or Video)
            if (mediaUrl != null)
              mediaType == 'video'
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio:
                              _videoController?.value.aspectRatio ?? 16 / 9,
                          child: _videoController != null &&
                                  _videoController!.value.isInitialized
                              ? VideoPlayer(_videoController!)
                              : const Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.primary)),
                        ),

                        // Full Screen Icon (Top Right)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: GestureDetector(
                            onTap: _openFullScreen,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                  color: Colors.black45,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.fullscreen,
                                  color: Colors.white, size: 28),
                            ),
                          ),
                        ),

                        // Mute Icon (Bottom Right)
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: GestureDetector(
                            onTap: _toggleMute,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                  color: Colors.black45,
                                  shape: BoxShape.circle),
                              child: Icon(
                                  _isMuted ? Icons.volume_off : Icons.volume_up,
                                  color: Colors.white,
                                  size: 20),
                            ),
                          ),
                        ),
                      ],
                    )
                  // Image Logic
                  : GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  FullScreenImage(imageUrl: mediaUrl))),
                      child: Hero(
                        tag: mediaUrl,
                        child: CachedNetworkImage(
                          imageUrl: mediaUrl,
                          width: double.infinity,
                          height: 350,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                              height: 350, color: AppColors.background),
                          errorWidget: (_, __, ___) =>
                              Container(height: 350, color: Colors.grey[200]),
                        ),
                      ),
                    ),

            // Footer Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.favorite_border, size: 26),
                      const SizedBox(width: 16),
                      const Icon(Icons.chat_bubble_outline, size: 24),
                      const SizedBox(width: 16),
                      const Icon(Icons.send_outlined, size: 24),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text("$likes likes",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (content != null) ...[
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        style:
                            const TextStyle(color: Colors.black, fontSize: 14),
                        children: [
                          const TextSpan(
                              text: "T Kairos Shop ",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: content),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- SIMPLE FULL SCREEN IMAGE VIEWER ---
class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  const FullScreenImage({super.key, required this.imageUrl});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: InteractiveViewer(
          // Allows pinch-to-zoom
          panEnabled: true,
          child: Hero(
            tag: imageUrl,
            child: CachedNetworkImage(imageUrl: imageUrl),
          ),
        ),
      ),
    );
  }
}
