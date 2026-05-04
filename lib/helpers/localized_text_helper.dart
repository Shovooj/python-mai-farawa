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
