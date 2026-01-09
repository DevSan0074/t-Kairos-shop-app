import 'dart:typed_data'; // Needed for bytes (Web safe)
import 'package:flutter/foundation.dart'; // Needed for kIsWeb check
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/sakura_button.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _contentCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  XFile? _pickedFile;
  Uint8List? _fileBytes; // File data in memory
  String _mediaType = 'image';
  bool _isLoading = false;
  VideoPlayerController? _videoController;

  @override
  void dispose() {
    _videoController?.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  // 1. Pick Media (Cross-Platform)
  Future<void> _pickMedia() async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            // Pick Image
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Pick Image'),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? image =
                    await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  final bytes = await image.readAsBytes();
                  setState(() {
                    _pickedFile = image;
                    _fileBytes = bytes;
                    _mediaType = 'image';
                    _videoController?.dispose();
                    _videoController = null;
                  });
                }
              },
            ),
            // Pick Video
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Pick Video'),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? video =
                    await _picker.pickVideo(source: ImageSource.gallery);
                if (video != null) {
                  // 1. Read bytes for upload
                  final bytes = await video.readAsBytes();

                  // 2. Initialize Player (Without dart:io File)
                  VideoPlayerController controller;
                  if (kIsWeb) {
                    // Web: Path is a blob URL
                    controller =
                        VideoPlayerController.networkUrl(Uri.parse(video.path));
                  } else {
                    // Mobile: Path is a local file path
                    controller =
                        VideoPlayerController.networkUrl(Uri.file(video.path));
                  }

                  await controller.initialize();
                  controller.setLooping(true);
                  controller.setVolume(0); // Mute preview
                  controller.play();

                  setState(() {
                    _pickedFile = video;
                    _fileBytes = bytes;
                    _mediaType = 'video';
                    _videoController = controller;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // 2. Upload & Post
  Future<void> _submit() async {
    final text = _contentCtrl.text.trim();
    if (text.isEmpty && _pickedFile == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Add text or media")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? publicUrl;

      // Upload Binary Data (Works on Web & Mobile)
      if (_pickedFile != null && _fileBytes != null) {
        final ext = _mediaType == 'video' ? 'mp4' : 'jpg';
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
        final path = 'uploads/$fileName';

        await Supabase.instance.client.storage.from('post_media').uploadBinary(
              path,
              _fileBytes!,
              fileOptions:
                  const FileOptions(cacheControl: '3600', upsert: false),
            );

        publicUrl = Supabase.instance.client.storage
            .from('post_media')
            .getPublicUrl(path);
      }

      // Insert Post Data
      await Supabase.instance.client.from('posts').insert({
        'content': text.isNotEmpty ? text : null,
        'image_url': publicUrl,
        'media_type': _mediaType,
        'likes': 0,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Error: $e"), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: const Text("Create Post"), backgroundColor: AppColors.surface),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _contentCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "What's happening?",
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Preview Area
            if (_pickedFile != null)
              Container(
                width: double.infinity,
                // Limit height so it fits on screen
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _mediaType == 'image'
                      ? Image.memory(_fileBytes!, fit: BoxFit.contain)
                      : (_videoController != null &&
                              _videoController!.value.isInitialized)
                          ? AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: VideoPlayer(_videoController!),
                            )
                          : const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary)),
                ),
              ),

            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                TextButton.icon(
                  onPressed: _pickMedia,
                  icon: const Icon(Icons.image, color: AppColors.primary),
                  label: const Text("Add Media",
                      style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 30),
            SakuraButton(
                text: "Post", isLoading: _isLoading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
