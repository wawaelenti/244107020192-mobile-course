import 'dart:convert';

import 'package:campus_notify/ai/ai_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('reuses cached text response without another API request', () async {
    final storage = _MemorySecureStorage()..values['ai_api_key'] = 'test-key';
    var requestCount = 0;
    final service = AiService(
      storage: storage,
      client: MockClient((request) async {
        requestCount++;
        expect(request.headers['x-goog-api-key'], 'test-key');
        return http.Response(_streamResponse('Jawaban tes'), 200);
      }),
    );
    addTearDown(service.close);

    expect(await service.ask('Apa kabar?').join(), 'Jawaban tes');
    expect(await service.ask('Apa kabar?').join(), 'Jawaban tes');
    expect(requestCount, 1);
    expect(storage.values['ai_daily_usage'], endsWith(':1'));
  });

  test('limits new requests to twenty per UTC day', () async {
    final storage = _MemorySecureStorage()..values['ai_api_key'] = 'test-key';
    var requestCount = 0;
    final service = AiService(
      storage: storage,
      client: MockClient((_) async {
        requestCount++;
        return http.Response(_streamResponse('Jawaban tes'), 200);
      }),
    );
    addTearDown(service.close);

    for (var index = 0; index < AiService.dailyRequestLimit; index++) {
      await service.ask('Pertanyaan $index').join();
    }

    await expectLater(
      service.ask('Pertanyaan tambahan').join(),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Batas harian'),
        ),
      ),
    );
    expect(requestCount, AiService.dailyRequestLimit);
  });
}

String _streamResponse(String text) {
  return 'data: ${jsonEncode({
    'candidates': [
      {
        'content': {
          'parts': [
            {'text': text},
          ],
        },
      },
    ],
  })}\n\n';
}

class _MemorySecureStorage extends FlutterSecureStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return values[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}
