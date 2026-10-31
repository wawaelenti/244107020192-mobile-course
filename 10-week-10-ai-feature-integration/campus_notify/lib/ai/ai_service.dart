import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AiService {
  AiService({FlutterSecureStorage? storage, http.Client? client})
    : _storage = storage ?? const FlutterSecureStorage(),
      _client = client ?? http.Client();

  static const _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/'
      'gemini-3.6-flash:streamGenerateContent';
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

    final uri = Uri.parse(_apiUrl).replace(queryParameters: {'alt': 'sse'});
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
