import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/loading_indicator.dart';
import 'chat_input.dart';

// Stream Messages
final chatStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>(
        (ref, otherUserId) {
  final myId = Supabase.instance.client.auth.currentUser!.id;

  // Listen to the stream
  return Supabase.instance.client
      .from('messages')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: true)
      .map((data) {
        // Filter locally to ensure we only see chat with THIS person
        return data.where((msg) {
          final sender = msg['user_id'];
          final receiver = msg['receiver_id'];
          return (sender == myId && receiver == otherUserId) ||
              (sender == otherUserId && receiver == myId);
        }).toList();
      });
});

// Fetch Name Provider
final profileNameProvider =
    FutureProvider.family<String, String>((ref, userId) async {
  final data = await Supabase.instance.client
      .from('profiles')
      .select()
      .eq('id', userId)
      .maybeSingle();

  if (data == null) return "Unknown User";

  if (data['username'] != null && data['username'].toString().isNotEmpty) {
    return data['username'];
  }
  if (data['email'] != null && data['email'].toString().isNotEmpty) {
    return data['email'];
  }

  return "User";
});

class ChatScreen extends ConsumerStatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatScreen(
      {super.key, required this.otherUserId, required this.otherUserName});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingUrl;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playAudio(String url) async {
    if (_playingUrl == url) {
      await _audioPlayer.stop();
      setState(() => _playingUrl = null);
    } else {
      await _audioPlayer.play(UrlSource(url));
      setState(() => _playingUrl = url);
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playingUrl = null);
      });
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString();
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatStreamProvider(widget.otherUserId));
    final nameAsync = ref.watch(profileNameProvider(widget.otherUserId));
    final myId = Supabase.instance.client.auth.currentUser!.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            nameAsync.when(
              data: (name) => Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              loading: () => Text(widget.otherUserName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              error: (_, __) => Text(widget.otherUserName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const Text("Online",
                style: TextStyle(fontSize: 10, color: Colors.green)),
          ],
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: chatAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                      child: Text("Say Hello! 👋",
                          style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['user_id'] == myId;
                    final isAudio = msg['is_audio'] == true;
                    final int duration = msg['duration'] ?? 0;

                    String time = "";
                    if (msg['created_at'] != null) {
                      time = DateFormat('hm')
                          .format(DateTime.parse(msg['created_at']).toLocal());
                    }

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        constraints: const BoxConstraints(maxWidth: 260),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft:
                                isMe ? const Radius.circular(18) : Radius.zero,
                            bottomRight:
                                isMe ? Radius.zero : const Radius.circular(18),
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // AUDIO BUBBLE
                            if (isAudio)
                              GestureDetector(
                                onTap: () => _playAudio(msg['audio_url'] ?? ""),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? Colors.white.withOpacity(0.2)
                                            : Colors.grey.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _playingUrl == msg['audio_url']
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: isMe
                                            ? Colors.white
                                            : AppColors.primary,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Voice Wave Graphic (FIXED)
                                    SizedBox(
                                      width: 80,
                                      height: 20,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: List.generate(
                                            10,
                                            (i) => Container(
                                                  width: 3,
                                                  height: (i % 2 == 0) ? 15 : 8,
                                                  // FIX: Moved color inside BoxDecoration
                                                  decoration: BoxDecoration(
                                                      color: isMe
                                                          ? Colors.white60
                                                          : Colors.grey[300],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10)),
                                                )),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // DURATION TEXT
                                    Text(
                                      _formatDuration(duration),
                                      style: TextStyle(
                                          color: isMe
                                              ? Colors.white
                                              : Colors.black87,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              )
                            // TEXT BUBBLE
                            else
                              Text(
                                msg['content'] ?? "",
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                            const SizedBox(height: 4),
                            // TIME
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe ? Colors.white70 : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              error: (e, s) => Center(child: Text("Error: $e")),
              loading: () => const SakuraLoading(),
            ),
          ),
          ChatInputArea(receiverId: widget.otherUserId),
        ],
      ),
    );
  }
}
