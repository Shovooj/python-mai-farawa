// Simple helper to pick localized text with a Hausa fallback.
// Parameters:
// - english: fallback English text.
// - hausa: Hausa translation (may be empty).
// - selectedLanguage: currently selected language code.
// Returns the selected language text or English if Hausa is empty.
String localizedText({
  required String english,
  required String hausa,
  required String selectedLanguage,
}) {
  if (selectedLanguage == 'ha' && hausa.trim().isNotEmpty) {
    return hausa;
  }
  return english;
}
