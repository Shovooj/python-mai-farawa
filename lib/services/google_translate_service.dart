import 'dart:convert';
import 'package:http/http.dart' as http;
import 'term_protection_service.dart';

// Wraps Google Translate REST API calls.
// Uses `TermProtectionService` to temporarily replace sensitive tokens
// (like code snippets or placeholder terms) before translation and restore
// them after receiving the translated text.
class GoogleTranslateService {
  final String apiKey;
  final TermProtectionService protectionService = TermProtectionService();

  GoogleTranslateService({required this.apiKey});

  // Translate `text` from `source` to `target` language using Google API.
  // Throws when API key is missing or when the HTTP call fails.
  Future<String> translateText({
    required String text,
    String source = 'en',
    String target = 'ha',
  }) async {
    if (text.trim().isEmpty) return '';

    if (apiKey.trim().isEmpty) {
      throw Exception('Google Translate API key is missing.');
    }

    // Protect terms that should not be translated (e.g., code, variable names)
    final protected = protectionService.protectTerms(text);

    final protectedText = (protected['text'] as String?) ?? text;
    final replacementsRaw = protected['replacements'];

    final Map<String, String> replacements = replacementsRaw is Map
        ? replacementsRaw.map(
            (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
          )
        : <String, String>{};

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

    // Restore protected terms into the translated text.
    return protectionService.restoreTerms(translated, replacements);
  }
}
