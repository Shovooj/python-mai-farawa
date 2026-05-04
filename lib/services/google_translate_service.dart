import 'dart:convert';
import 'package:http/http.dart' as http;
import 'term_protection_service.dart';

class GoogleTranslateService {
  final String apiKey;
  final TermProtectionService protectionService = TermProtectionService();

  GoogleTranslateService({required this.apiKey});

  Future<String> translateText({
    required String text,
    String source = 'en',
    String target = 'ha',
  }) async {
    if (text.trim().isEmpty) return '';

    if (apiKey.trim().isEmpty) {
      throw Exception('Google Translate API key is missing.');
    }

    final protected = protectionService.protectTerms(text);
    final protectedText = protected['text'] as String;
    final replacements = Map<String, String>.from(
      protected['replacements'] as Map,
    );

    final uri = Uri.parse(
      'https://translation.googleapis.com/language/translate/v2?key=$apiKey',
    );

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'q': protectedText,
        'source': source,
        'target': target,
        'format': 'text',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Translation failed: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final translated =
        data['data']['translations'][0]['translatedText'] as String;

    return protectionService.restoreTerms(translated, replacements);
  }
}
