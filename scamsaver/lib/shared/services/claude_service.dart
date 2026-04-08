import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

enum RiskLevel { low, medium, high, critical, unknown }

class AnalysisResult {
  final RiskLevel riskLevel;
  final String explanation;
  final List<String> redFlags;

  const AnalysisResult({
    required this.riskLevel,
    required this.explanation,
    required this.redFlags,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    final level = (json['risk_level'] as String? ?? 'unknown').toLowerCase();
    return AnalysisResult(
      riskLevel: RiskLevel.values.firstWhere(
        (e) => e.name == level,
        orElse: () => RiskLevel.unknown,
      ),
      explanation: json['explanation'] as String? ?? 'No explanation provided.',
      redFlags: List<String>.from(json['red_flags'] ?? []),
    );
  }
}

class ClaudeService {
  final Dio _dio;
  final String _apiKey;

  ClaudeService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'https://api.anthropic.com',
            headers: {
              'Content-Type': 'application/json',
              'anthropic-version': '2023-06-01',
            },
          ),
        ),
        _apiKey = const String.fromEnvironment('ANTHROPIC_API_KEY');

  Future<AnalysisResult> analyzeText(String text) async {
    if (_apiKey.isEmpty) {
      throw Exception('ANTHROPIC_API_KEY not set. Use --dart-define=ANTHROPIC_API_KEY=...');
    }

    final response = await _dio.post(
      '/v1/messages',
      options: Options(
        headers: {'x-api-key': _apiKey},
      ),
      data: {
        'model': 'claude-3-5-haiku-20241022',
        'max_tokens': 1024,
        'messages': [
          {
            'role': 'user',
            'content': '''Analyze this message for scam indicators. Return ONLY a JSON object with this structure:
{ "risk_level": "low|medium|high|critical", "explanation": "...", "red_flags": [] }

Message to analyze: $text''',
          }
        ],
      },
    );

    final content = response.data['content'] as List;
    final textContent = content.firstWhere((c) => c['type'] == 'text')['text'] as String;

    // Extract JSON from response
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(textContent);
    if (jsonMatch == null) {
      throw Exception('Invalid response format from Claude API');
    }

    return AnalysisResult.fromJson(jsonDecode(jsonMatch.group(0)!));
  }
}

class WhisperService {
  final Dio _dio;
  final String _apiKey;

  WhisperService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'https://api.openai.com',
            headers: {
              'Content-Type': 'multipart/form-data',
            },
          ),
        ),
        _apiKey = const String.fromEnvironment('OPENAI_API_KEY');

  Future<String> transcribeAudio(File audioFile) async {
    if (_apiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY not set. Use --dart-define=OPENAI_API_KEY=...');
    }

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(audioFile.path),
      'model': 'whisper-1',
    });

    final response = await _dio.post(
      '/v1/audio/transcriptions',
      options: Options(
        headers: {'Authorization': 'Bearer $_apiKey'},
      ),
      data: formData,
    );

    return response.data['text'] as String;
  }
}
