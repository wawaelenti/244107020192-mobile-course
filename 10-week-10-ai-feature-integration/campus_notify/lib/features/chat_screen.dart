import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../ai/ai_service.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  final service = AiService();
  ref.onDispose(service.close);
  return service;
});

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final _audioRecorder = AudioRecorder();
  final List<_ChatMessage> _messages = [];
  bool _isSending = false;
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  AiService get _aiService => ref.read(aiServiceProvider);

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _recordingTimer?.cancel();
    unawaited(_audioRecorder.dispose());
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final question = _messageController.text.trim();
    if (question.isEmpty || _isSending || _isRecording) return;

    _messageController.clear();
    _beginRequest(text: question);

    try {
      await for (final chunk in _aiService.ask(question)) {
        if (!mounted) return;
        setState(() {
          final current = _messages.last;
          _messages[_messages.length - 1] = current.copyWith(
            text: '${current.text}$chunk',
          );
        });
        _scrollToBottom();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages[_messages.length - 1] = _messages.last.copyWith(
          text: _messageFromError(error),
          isError: true,
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  String _messageFromError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _beginRequest({required String text, String? imagePath}) {
    setState(() {
      _isSending = true;
      _messages
        ..add(_ChatMessage(text: text, isUser: true, imagePath: imagePath))
        ..add(_ChatMessage(text: '', isUser: false));
    });
    _scrollToBottom();
  }

  void _finishRequest(String text, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _messages[_messages.length - 1] = _messages.last.copyWith(
        text: text,
        isError: isError,
      );
      _isSending = false;
    });
    _scrollToBottom();
  }

  Future<void> _runMediaRequest({
    required String userText,
    String? imagePath,
    required Future<String> Function() request,
  }) async {
    if (_isSending || !mounted) return;
    _beginRequest(text: userText, imagePath: imagePath);
    try {
      _finishRequest(await request());
    } catch (error) {
      _finishRequest(_messageFromError(error), isError: true);
    }
  }

  Future<void> _showImagePickerOptions() async {
    if (_isSending || _isRecording) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil dari kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (image == null || !mounted) return;

      final task = await showModalBottomSheet<_ImageTask>(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.text_snippet_outlined),
                title: const Text('Ekstrak teks (OCR)'),
                onTap: () => Navigator.pop(context, _ImageTask.ocr),
              ),
              ListTile(
                leading: const Icon(Icons.image_search_outlined),
                title: const Text('Deskripsikan gambar'),
                onTap: () => Navigator.pop(context, _ImageTask.describe),
              ),
            ],
          ),
        ),
      );
      if (task == null || !mounted) return;

      final file = File(image.path);
      final isOcr = task == _ImageTask.ocr;
      await _runMediaRequest(
        userText: isOcr ? 'Ekstrak teks dari gambar' : 'Deskripsikan gambar',
        imagePath: image.path,
        request: () => isOcr
            ? _aiService.recognizeText(file)
            : _aiService.describeImage(file),
      );
    } on PlatformException catch (error) {
      if (mounted) _showMessage('Gagal membuka gambar: ${error.message}');
    } catch (error) {
      if (mounted) _showMessage('Gagal memproses gambar: $error');
    }
  }

  Future<void> _toggleRecording() async {
    if (_isSending) return;
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      if (!await _audioRecorder.hasPermission()) {
        if (mounted) _showMessage('Izin mikrofon diperlukan untuk merekam.');
        return;
      }

      final directory = await getTemporaryDirectory();
      final filePath = path.join(
        directory.path,
        'campus_notify_${DateTime.now().millisecondsSinceEpoch}.wav',
      );
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: filePath,
      );

      if (!mounted) {
        await _audioRecorder.cancel();
        return;
      }

      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _recordingSeconds++);
        if (_recordingSeconds >= 60) unawaited(_stopRecording());
      });
    } catch (error) {
      if (mounted) _showMessage('Gagal memulai rekaman: $error');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    _recordingTimer?.cancel();
    _recordingTimer = null;
    setState(() => _isRecording = false);

    try {
      final filePath = await _audioRecorder.stop();
      if (filePath == null || filePath.isEmpty) {
        if (mounted) _showMessage('Rekaman tidak berhasil disimpan.');
        return;
      }

      final audioFile = File(filePath);
      try {
        await _runMediaRequest(
          userText: 'Transkripsikan rekaman suara',
          request: () => _aiService.speechToText(audioFile),
        );
      } finally {
        if (await audioFile.exists()) {
          try {
            await audioFile.delete();
          } catch (error) {
            if (mounted) {
              _showMessage('Gagal menghapus rekaman sementara: $error');
            }
          }
        }
      }
    } catch (error) {
      if (mounted) _showMessage('Gagal memproses rekaman: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String get _recordingDuration {
    final minutes = (_recordingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_recordingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _configureApiKey() async {
    final controller = TextEditingController();
    final key = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Atur Gemini API key'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(
            labelText: 'API key',
            hintText: 'Tempel API key dari Google AI Studio',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (key == null || !mounted) return;
    if (key.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key tidak boleh kosong.')),
      );
      return;
    }

    try {
      await _aiService.saveApiKey(key);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gemini API key berhasil disimpan.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan API key: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat dengan AI'),
        actions: [
          IconButton(
            tooltip: 'Atur API key',
            onPressed: _configureApiKey,
            icon: const Icon(Icons.key_outlined),
          ),
          IconButton(
            tooltip: 'Hapus percakapan',
            onPressed: _isSending ? null : () => setState(_messages.clear),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _MessageBubble(
                        message: message,
                        showLoading:
                            _isSending &&
                            index == _messages.length - 1 &&
                            message.text.isEmpty,
                      );
                    },
                  ),
          ),
          _buildComposer(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 56, color: colors.primary),
            const SizedBox(height: 16),
            Text(
              'Tanya apa saja ke Gemini',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Atur API key lewat ikon kunci. Kamu juga bisa mengirim gambar '
              'untuk OCR atau merekam suara untuk transkripsi.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isRecording)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.fiber_manual_record, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('Merekam $_recordingDuration (maks. 01:00)'),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Pilih gambar untuk OCR atau deskripsi',
                  onPressed: _isSending || _isRecording
                      ? null
                      : _showImagePickerOptions,
                  icon: const Icon(Icons.image_outlined),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_isSending && !_isRecording,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Tulis pesan...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _isRecording ? 'Selesai merekam' : 'Rekam suara',
                  onPressed: _isSending ? null : _toggleRecording,
                  style: _isRecording
                      ? IconButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        )
                      : null,
                  icon: Icon(
                    _isRecording ? Icons.stop_circle_outlined : Icons.mic_none,
                  ),
                ),
                IconButton.filled(
                  tooltip: 'Kirim pesan',
                  onPressed: _isSending || _isRecording ? null : _sendMessage,
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.imagePath,
    this.isError = false,
  });

  final String text;
  final bool isUser;
  final String? imagePath;
  final bool isError;

  _ChatMessage copyWith({String? text, bool? isError}) {
    return _ChatMessage(
      text: text ?? this.text,
      isUser: isUser,
      imagePath: imagePath,
      isError: isError ?? this.isError,
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.showLoading});

  final _ChatMessage message;
  final bool showLoading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final backgroundColor = message.isError
        ? colors.errorContainer
        : message.isUser
        ? colors.primary
        : colors.surfaceContainerHighest;
    final foregroundColor = message.isError
        ? colors.onErrorContainer
        : message.isUser
        ? colors.onPrimary
        : colors.onSurface;

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.imagePath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(message.imagePath!),
                    width: 220,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(
                          width: 220,
                          height: 80,
                          child: Center(child: Text('Gambar tidak tersedia')),
                        ),
                  ),
                ),
              ),
            if (showLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foregroundColor,
                ),
              )
            else
              SelectableText(
                message.text,
                style: TextStyle(color: foregroundColor),
              ),
          ],
        ),
      ),
    );
  }
}

enum _ImageTask { ocr, describe }
