import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/listing_draft.dart';

class GeminiVisionService {
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _model = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3.5-flash',
  );

  final http.Client _client;

  GeminiVisionService({http.Client? client})
    : _client = client ?? http.Client();

  Future<ListingDraft> analyzeProductImage({
    required File image,
    required String prompt,
    bool strictSafety = false,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'ไม่พบ Gemini API Key กรุณารันด้วย '
        '--dart-define=GEMINI_API_KEY=YOUR_API_KEY',
      );
    }

    final imageBytes = await image.readAsBytes();
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$_model:generateContent',
    );
    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inlineData': {
                'mimeType': _mimeTypeFor(image.path),
                'data': base64Encode(imageBytes),
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.2,
        'maxOutputTokens': 2048,
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'title': {'type': 'STRING'},
            'category': {
              'type': 'STRING',
              'enum': [
                'หนังสือเรียน',
                'อุปกรณ์อิเล็กทรอนิกส์',
                'ของแต่งหอพัก',
                'เสื้อผ้า',
                'อื่นๆ',
              ],
            },
            'description': {'type': 'STRING'},
          },
          'required': ['title', 'category', 'description'],
        },
      },
      if (strictSafety)
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_LOW_AND_ABOVE',
          },
        ],
    };

    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': _apiKey,
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 60));

      debugPrint('Gemini Vision HTTP ${response.statusCode}: ${response.body}');
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        throw Exception(_apiErrorMessage(response.statusCode, responseBody));
      }

      final promptFeedback =
          responseBody['promptFeedback'] as Map<String, dynamic>?;
      if (promptFeedback?['blockReason'] != null) {
        throw Exception(
          'เนื้อหาที่วิเคราะห์เข้าข่ายไม่ปลอดภัยตามนโยบายของ Gemini '
          'กรุณาใช้ภาพอื่น',
        );
      }

      final candidates = responseBody['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception(
          'AI ไม่สามารถวิเคราะห์ภาพนี้ได้ อาจเข้าข่ายเนื้อหาที่ไม่เหมาะสม '
          'ลองใช้ภาพอื่น',
        );
      }

      final candidate = candidates.first as Map<String, dynamic>;
      if (candidate['finishReason'] == 'SAFETY') {
        throw Exception(
          'เนื้อหาที่วิเคราะห์เข้าข่ายไม่ปลอดภัยตามนโยบายของ Gemini '
          'กรุณาใช้ภาพอื่น',
        );
      }

      final content = candidate['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      final text = _extractResponseText(parts);
      if (text == null || text.trim().isEmpty) {
        throw Exception('Gemini ส่งผลการวิเคราะห์ว่างกลับมา');
      }

      debugPrint('Gemini Vision raw response: $text');
      final draftJson = _decodeDraftJson(text);
      return ListingDraft.fromJson(draftJson);
    } on TimeoutException {
      throw Exception('Gemini ใช้เวลาวิเคราะห์นานเกิน 60 วินาที กรุณาลองใหม่');
    } on http.ClientException {
      throw Exception('ไม่สามารถเชื่อมต่อ Gemini ได้ กรุณาตรวจสอบอินเทอร์เน็ต');
    } on FormatException {
      throw Exception('ผลลัพธ์จาก Gemini ไม่ใช่ JSON ที่ถูกต้อง');
    }
  }

  String? _extractResponseText(List<dynamic>? parts) {
    if (parts == null || parts.isEmpty) return null;

    // Gemini รุ่นที่มี thinking อาจส่ง thought part มาก่อนคำตอบจริง
    // จึงเลือก text part สุดท้ายที่ไม่ใช่ thought
    final answerParts = parts
        .whereType<Map<String, dynamic>>()
        .where((part) => part['thought'] != true)
        .map((part) => part['text'])
        .whereType<String>()
        .where((text) => text.trim().isNotEmpty)
        .toList();

    if (answerParts.isNotEmpty) return answerParts.join().trim();

    final allTextParts = parts
        .whereType<Map<String, dynamic>>()
        .map((part) => part['text'])
        .whereType<String>()
        .where((text) => text.trim().isNotEmpty)
        .toList();
    return allTextParts.isEmpty ? null : allTextParts.join().trim();
  }

  Map<String, dynamic> _decodeDraftJson(String text) {
    var cleaned = text.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'\s*```$'), '');
    }

    // Structured output ปกติจะ decode ได้ตรง ๆ
    final direct = _tryJsonDecode(cleaned);
    if (direct is Map<String, dynamic>) return direct;

    // บางโมเดลอาจคืน JSON เป็น string ที่ถูก encode ซ้ำอีกชั้น
    if (direct is String) {
      final nested = _tryJsonDecode(direct);
      if (nested is Map<String, dynamic>) return nested;
    }

    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start == -1 || end < start) {
      throw const FormatException('ไม่พบ JSON object ในคำตอบ');
    }
    final extracted = _tryJsonDecode(cleaned.substring(start, end + 1));
    if (extracted is Map<String, dynamic>) return extracted;

    throw const FormatException('JSON object มีรูปแบบไม่ถูกต้อง');
  }

  Object? _tryJsonDecode(String source) {
    try {
      return jsonDecode(source);
    } on FormatException {
      return null;
    }
  }

  String _mimeTypeFor(String path) {
    final extension = path.split('.').last.toLowerCase();
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' || 'heif' => 'image/heic',
      _ => 'image/jpeg',
    };
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
