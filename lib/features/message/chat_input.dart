import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_colors.dart';

class ChatInputArea extends StatefulWidget {
  final String receiverId;
  const ChatInputArea({super.key, required this.receiverId});

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textCtrl = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  bool _hasText = false;
  bool _isCanceling = false;

  Timer? _timer;
  int _recordDuration = 0;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      lowerBound: 1.0,
      upperBound: 1.2,
    );

    _textCtrl.addListener(() {
      setState(() {
        _hasText = _textCtrl.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _audioRecorder.dispose();
    _textCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  void _startTimer() {
    _recordDuration = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _recordDuration++);
    });
  }

  // --- SEND TEXT ---
  Future<void> _sendText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    _textCtrl.clear();
    setState(() => _hasText = false);

    try {
      final myId = Supabase.instance.client.auth.currentUser!.id;

      await Supabase.instance.client.from('messages').insert({
        'content': text,
        'user_id': myId,
        'receiver_id': widget.receiverId,
        'is_audio': false,
        'duration': 0,
      });
    } catch (e) {
      debugPrint("Error sending text: $e");
    }
  }

  // --- START RECORDING ---
  Future<void> _startRecording() async {
    if (_hasText) return;

    if (!kIsWeb) {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) return;
    }

    String path = '';
    if (!kIsWeb) {
      final dir = await getTemporaryDirectory();
      path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    }

    await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path.isEmpty ? '' : path);

    _startTimer();
    setState(() {
      _isRecording = true;
      _isCanceling = false;
    });
    _animController.repeat(reverse: true);
  }

  // --- STOP & SEND AUDIO ---
  Future<void> _stopRecording({required bool isCancelled}) async {
    _timer?.cancel();
    _animController.reset();

    final path = await _audioRecorder.stop();
    final duration = _recordDuration; // Capture duration before reset

    setState(() {
      _isRecording = false;
      _isCanceling = false;
      _recordDuration = 0;
    });

    if (isCancelled || path == null) return;

    try {
      final myId = Supabase.instance.client.auth.currentUser!.id;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.m4a';
      final storagePath = 'voice/$fileName';

      Uint8List fileBytes;
      if (kIsWeb) {
        final response = await http.get(Uri.parse(path));
        fileBytes = response.bodyBytes;
      } else {
        fileBytes = await File(path).readAsBytes();
      }

      await Supabase.instance.client.storage.from('chat_voice').uploadBinary(
          storagePath, fileBytes,
          fileOptions: const FileOptions(contentType: 'audio/x-m4a'));

      final publicUrl = Supabase.instance.client.storage
          .from('chat_voice')
          .getPublicUrl(storagePath);

      // SAVE TO DB WITH DURATION
      await Supabase.instance.client.from('messages').insert({
        'content': 'Voice Message',
        'user_id': myId,
        'receiver_id': widget.receiverId,
        'is_audio': true,
        'audio_url': publicUrl,
        'duration': duration, // Saved here!
      });
    } catch (e) {
      debugPrint("Error sending audio: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color activeColor = _isCanceling ? Colors.red : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Text Input
                  Visibility(
                    visible: !_isRecording,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _textCtrl,
                        decoration: const InputDecoration(
                          hintText: "Type a message...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),

                  // Recording UI
                  if (_isRecording)
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: _isCanceling ? Colors.red.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          FadeTransition(
                            opacity: _animController,
                            child: const Icon(Icons.fiber_manual_record,
                                color: Colors.red, size: 20),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDuration(_recordDuration),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Spacer(),
                          Text(
                            _isCanceling
                                ? "Release to Delete"
                                : "< Slide to Cancel",
                            style: TextStyle(
                              color: _isCanceling ? Colors.red : Colors.grey,
                              fontWeight: _isCanceling
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Action Button
            _hasText
                ? GestureDetector(
                    onTap: _sendText,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle),
                      child:
                          const Icon(Icons.send, color: Colors.white, size: 24),
                    ),
                  )
                : GestureDetector(
                    onLongPressStart: (_) => _startRecording(),
                    onLongPressMoveUpdate: (details) {
                      if (details.localPosition.dx < -60) {
                        if (!_isCanceling) setState(() => _isCanceling = true);
                      } else {
                        if (_isCanceling) setState(() => _isCanceling = false);
                      }
                    },
                    onLongPressEnd: (_) {
                      _stopRecording(isCancelled: _isCanceling);
                    },
                    child: ScaleTransition(
                      scale: _animController,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: activeColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: activeColor.withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 2)
                          ],
                        ),
                        child: Icon(
                          _isCanceling
                              ? Icons.delete_outline
                              : (_isRecording ? Icons.mic : Icons.mic_none),
                          color: Colors.white,
                          size: 24,
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
