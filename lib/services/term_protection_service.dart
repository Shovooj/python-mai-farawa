// Protects programming-related terms from being translated by external
// translation services. It replaces protected terms with placeholders before
// translation and restores them afterward.
class TermProtectionService {
  static const List<String> protectedTerms = [
    'Python',
    'print',
    'input',
    'if',
    'else',
    'elif',
    'for',
    'while',
    'list',
    'tuple',
    'dictionary',
    'string',
    'integer',
    'float',
    'boolean',
    'variable',
    'function',
    'loop',
    'syntax',
    'indentation',
    'True',
    'False',
    'None',
    'Functions',
    'Function',
    'If',
    'Operators',
    'info',
    'version',
    'class',
    'type',
    'modulus',
    'Else if',
    'Else in',
    'Else it',
    'Else is',
    'return',
    'fruits',
  ];

  // Replaces protected terms with unique placeholders and returns the
  // transformed text along with a map of placeholders -> original terms.
  Map<String, dynamic> protectTerms(String text) {
    String protectedText = text;
    final Map<String, String> replacements = {};

    for (int i = 0; i < protectedTerms.length; i++) {
      final term = protectedTerms[i];
      final placeholder = '__TERM_${i}__';
      protectedText = protectedText.replaceAll(term, placeholder);
      replacements[placeholder] = term;
    }

    return {'text': protectedText, 'replacements': replacements};
  }

  // Restores placeholders in `text` back to their original protected terms.
  String restoreTerms(String text, Map<String, String> replacements) {
    String restored = text;
    replacements.forEach((placeholder, term) {
      restored = restored.replaceAll(placeholder, term);
    });
    return restored;
  }
}
