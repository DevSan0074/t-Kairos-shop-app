import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/loading_indicator.dart';
import '../providers.dart';
import 'create_post_page.dart';

// Check if Admin
final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return false;
  final data = await Supabase.instance.client
      .from('profiles')
      .select('is_admin')
      .eq('id', user.id)
      .maybeSingle();
  return data != null && data['is_admin'] == true;
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);
    final isAdminAsync = ref.watch(isAdminProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text("T Kairos",
            style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold)),
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
      ),

      // Admin Post Button (Moved up to avoid covering by navbar)
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: isAdminAsync.when(
        data: (isAdmin) => isAdmin
            ? Padding(
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

      body: postsAsync.when(
        data: (data) {
          if (data.isEmpty) return const Center(child: Text("No posts yet."));

          // ADDED: RefreshIndicator allows "Pull to Refresh" if post doesn't show instantly
          return RefreshIndicator(
            onRefresh: () async {
              return ref.refresh(postsProvider);
            },
            color: AppColors.primary,
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 120),
              itemCount: data.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final post = data[index];
                return PostItem(post: post);
              },
            ),
          );
        },
        error: (e, st) => Center(child: Text('Error loading feed: $e')),
        loading: () => const SakuraLoading(),
      ),
    );
  }
}

// Separate Widget to handle Video & Image Logic
class PostItem extends StatefulWidget {
  final Map<String, dynamic> post;
  const PostItem({super.key, required this.post});

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  VideoPlayerController? _videoController;
  bool _isPlaying = false;

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
            _videoController!.setVolume(0.0); // Mute by default
            _videoController!.setLooping(true);
            _videoController!.play();
            _isPlaying = true;
          }
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _toggleVideo() {
    if (_videoController == null) return;
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
      } else {
        _videoController!.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String? mediaUrl = widget.post['image_url'];
    final String? mediaType = widget.post['media_type'];
    final String? content = widget.post['content'];
    final int likes = widget.post['likes'] ?? 0;

    return Container(
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

          // MEDIA AREA
          if (mediaUrl != null)
            mediaType == 'video'
                ? GestureDetector(
                    onTap: _toggleVideo,
                    child: Stack(
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
                        if (!_isPlaying)
                          const Icon(Icons.play_circle_fill,
                              color: Colors.white70, size: 50),
                      ],
                    ),
                  )
                // ADDED: GestureDetector here to allow Clicking Image
                : GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  FullScreenImage(imageUrl: mediaUrl)));
                    },
                    child: Hero(
                      tag: mediaUrl,
                      child: CachedNetworkImage(
                        imageUrl: mediaUrl,
                        width: double.infinity,
                        height: 350,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(height: 350, color: AppColors.background),
                        errorWidget: (_, __, ___) =>
                            Container(height: 350, color: Colors.grey[200]),
                      ),
                    ),
                  ),

          // Actions
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
                      style: const TextStyle(color: Colors.black, fontSize: 14),
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
    );
  }
}

// Full Screen Zoom View
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
