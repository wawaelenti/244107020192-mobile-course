import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AiService {
  AiService({FlutterSecureStorage? storage, http.Client? client})
    : _storage = storage ?? const FlutterSecureStorage(),
      _client = client ?? http.Client();

  static const _modelUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/'
      'gemini-3.6-flash';
  static const _inlineFileLimit = 15 * 1024 * 1024;
  static const _apiKeyStorageKey = 'ai_api_key';

  final FlutterSecureStorage _storage;
  final http.Client _client;

  Future<String?> readApiKey() {
    return _storage.read(key: _apiKeyStorageKey);
  }

  Future<void> saveApiKey(String key) async {
    final trimmedKey = key.trim();
    if (trimmedKey.isEmpty) {
      throw ArgumentError.value(key, 'key', 'API key tidak boleh kosong.');
    }

    await _storage.write(key: _apiKeyStorageKey, value: trimmedKey);
  }

  Stream<String> ask(String question) async* {
    final trimmedQuestion = question.trim();
    if (trimmedQuestion.isEmpty) {
      throw ArgumentError.value(
        question,
        'question',
        'Pertanyaan tidak boleh kosong.',
      );
    }

    final apiKey = await readApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'API key belum tersedia. Ketuk ikon kunci untuk mengaturnya.',
      );
    }

    final uri = Uri.parse('$_modelUrl:streamGenerateContent')
        .replace(queryParameters: {'alt': 'sse'});
    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..headers['x-goog-api-key'] = apiKey
      ..body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': trimmedQuestion},
            ],
          },
        ],
      });

    final response = await _client
        .send(request)
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      final responseBody = await response.stream.bytesToString().timeout(
        const Duration(seconds: 60),
      );
      throw Exception(_errorMessage(response.statusCode, responseBody));
    }

    var receivedText = false;
    final lines = utf8.decoder
        .bind(response.stream)
        .transform(const LineSplitter())
        .timeout(const Duration(seconds: 60));

    await for (final line in lines) {
      if (!line.startsWith('data:')) continue;
      final payload = line.substring(5).trim();
      if (payload.isEmpty || payload == '[DONE]') continue;

      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) continue;

      final candidates = decoded['candidates'];
      if (candidates is! List || candidates.isEmpty) continue;

      final candidate = candidates.first;
      if (candidate is! Map<String, dynamic>) continue;

      final content = candidate['content'];
      if (content is! Map<String, dynamic>) continue;

      final parts = content['parts'];
      if (parts is! List) continue;

      for (final part in parts) {
        if (part is Map<String, dynamic> &&
            part['thought'] != true &&
            part['text'] is String) {
          final text = part['text'] as String;
          if (text.isNotEmpty) {
            receivedText = true;
            yield text;
          }
        }
      }
    }

    if (!receivedText) {
      throw Exception('Gemini tidak mengembalikan teks untuk pertanyaan ini.');
    }
  }

  Future<String> recognizeText(File imageFile) {
    return _generateFromFile(
      file: imageFile,
      prompt:
          'Ekstrak semua teks yang terlihat pada gambar. Pertahankan urutan '
          'baris dan tata letaknya sebisa mungkin. Jika tidak ada teks yang '
          'terbaca, jelaskan bahwa teks tidak ditemukan.',
      mimeType: _imageMimeType(imageFile.path),
    );
  }

  Future<String> describeImage(File imageFile) {
    return _generateFromFile(
      file: imageFile,
      prompt:
          'Deskripsikan gambar ini dengan jelas dan ringkas. Sebutkan objek '
          'dan detail penting yang terlihat tanpa menebak informasi yang '
          'tidak dapat dipastikan dari gambar.',
      mimeType: _imageMimeType(imageFile.path),
    );
  }

  Future<String> speechToText(File audioFile) {
    return _generateFromFile(
      file: audioFile,
      prompt:
          'Transkripsikan seluruh ucapan dalam audio ini dengan akurat. '
          'Gunakan bahasa yang sama dengan pembicara dan keluarkan hanya '
          'teks transkripsinya. Jika tidak ada ucapan yang dapat dikenali, '
          'jelaskan bahwa ucapan tidak ditemukan.',
      mimeType: 'audio/wav',
    );
  }

  Future<String> _generateFromFile({
    required File file,
    required String prompt,
    required String mimeType,
  }) async {
    final apiKey = await readApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'API key belum tersedia. Ketuk ikon kunci untuk mengaturnya.',
      );
    }

    if (!await file.exists()) {
      throw Exception('File yang dipilih tidak ditemukan.');
    }

    final fileSize = await file.length();
    if (fileSize == 0) {
      throw Exception('File yang dipilih kosong.');
    }
    if (fileSize > _inlineFileLimit) {
      throw Exception(
        'Ukuran file melebihi batas 15 MB. Pilih file yang lebih kecil.',
      );
    }

    final uri = Uri.parse('$_modelUrl:generateContent');
    final response = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                  {
                    'inlineData': {
                      'mimeType': mimeType,
                      'data': base64Encode(await file.readAsBytes()),
                    },
                  },
                ],
              },
            ],
          }),
        )
        .timeout(const Duration(seconds: 120));

    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response.statusCode, response.body));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final candidates = decoded['candidates'];
      if (candidates is List && candidates.isNotEmpty) {
        final candidate = candidates.first;
        if (candidate is Map<String, dynamic>) {
          final content = candidate['content'];
          if (content is Map<String, dynamic>) {
            final parts = content['parts'];
            if (parts is List) {
              final text = parts
                  .whereType<Map<String, dynamic>>()
                  .where((part) => part['thought'] != true)
                  .map((part) => part['text'])
                  .whereType<String>()
                  .join();
              if (text.trim().isNotEmpty) return text.trim();
            }
          }
        }
      }

      final promptFeedback = decoded['promptFeedback'];
      if (promptFeedback is Map<String, dynamic> &&
          promptFeedback['blockReason'] is String) {
        throw Exception(
          'Permintaan ditolak Gemini: ${promptFeedback['blockReason']}.',
        );
      }
    }

    throw Exception('Gemini tidak mengembalikan teks untuk file ini.');
  }

  String _imageMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => throw ArgumentError('Format gambar .$extension tidak didukung.'),
    };
  }

  String _errorMessage(int statusCode, String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic> && error['message'] is String) {
          return 'Gemini API ($statusCode): ${error['message']}';
        }
      }
    } on FormatException {
      // Use the status code below when the API response is not JSON.
    }

    return 'Gagal memanggil Gemini API (HTTP $statusCode).';
  }

  void close() {
    _client.close();
  }
}
