import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class GeminiService {
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _model = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3.5-flash',
  );

  final http.Client _client;

  GeminiService({http.Client? client}) : _client = client ?? http.Client();

  Future<String> generateText(String prompt) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'ไม่พบ Gemini API Key กรุณารันด้วย '
        '--dart-define=GEMINI_API_KEY=YOUR_API_KEY',
      );
    }

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$_model:generateContent',
    );

    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': _apiKey,
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 20));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        throw Exception(_apiErrorMessage(response.statusCode, body));
      }

      final candidates = body['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('AI ไม่สามารถสร้างคำตอบได้ กรุณาลองใหม่อีกครั้ง');
      }

      final candidate = candidates.first as Map<String, dynamic>;
      if (candidate['finishReason'] == 'SAFETY') {
        throw Exception('คำขอถูกปฏิเสธตามนโยบายความปลอดภัยของ Gemini');
      }

      final content = candidate['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      final text = parts?.isNotEmpty == true
          ? (parts!.first as Map<String, dynamic>)['text'] as String?
          : null;
      if (text == null || text.trim().isEmpty) {
        throw Exception('AI ส่งคำตอบว่างกลับมา กรุณาลองใหม่อีกครั้ง');
      }
      return text.trim();
    } on TimeoutException {
      throw Exception('Gemini ใช้เวลาตอบนานเกิน 20 วินาที กรุณาลองใหม่');
    } on http.ClientException {
      throw Exception('ไม่สามารถเชื่อมต่อ Gemini ได้ กรุณาตรวจสอบอินเทอร์เน็ต');
    } on FormatException {
      throw Exception('ข้อมูลตอบกลับจาก Gemini ไม่ถูกต้อง');
    }
  }

  String _apiErrorMessage(int statusCode, Map<String, dynamic> body) {
    final error = body['error'] as Map<String, dynamic>?;
    final detail = error?['message'] as String?;
    if (statusCode == 429) return 'ใช้งานเกินโควตาชั่วคราว กรุณารอสักครู่';
    if (statusCode == 503) return 'เซิร์ฟเวอร์ Gemini ไม่พร้อมใช้งานชั่วคราว';
    if (statusCode == 400 || statusCode == 403) {
      return 'API Key ไม่ถูกต้องหรือไม่มีสิทธิ์ใช้งาน Gemini';
    }
    return detail ?? 'Gemini API ตอบกลับรหัส $statusCode';
  }
}
