import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_config.dart';
import 'google_translate_service.dart';

// Translates practice content to Hausa when missing. Uses Google Translate
// and avoids changing already-provided Hausa fields.
class PracticeTranslationService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> translatePracticeToHausa({
    required String practiceId,
    required String title,
    required String instruction,
    required String expectedOutput,
    String? titleHa,
    String? instructionHa,
    String? expectedOutputHa,
  }) async {
    final translator = GoogleTranslateService(
      apiKey: AppConfig.googleTranslateApiKey,
    );

    final needsTitleTranslation = (titleHa ?? '').trim().isEmpty;
    final needsInstructionTranslation = (instructionHa ?? '').trim().isEmpty;
    final needsExpectedOutputTranslation = (expectedOutputHa ?? '')
        .trim()
        .isEmpty;

    if (!needsTitleTranslation &&
        !needsInstructionTranslation &&
        !needsExpectedOutputTranslation) {
      return;
    }

    String newTitleHa = titleHa ?? '';
    String newInstructionHa = instructionHa ?? '';
    String newExpectedOutputHa = expectedOutputHa ?? '';

    if (needsTitleTranslation) {
      newTitleHa = await translator.translateText(text: title);
    }

    if (needsInstructionTranslation) {
      newInstructionHa = await translator.translateText(text: instruction);
    }

    if (needsExpectedOutputTranslation) {
      newExpectedOutputHa = await translator.translateText(
        text: expectedOutput,
      );
    }

    await firestore.collection('practices').doc(practiceId).update({
      'titleHa': newTitleHa,
      'instructionHa': newInstructionHa,
      'expectedOutputHa': newExpectedOutputHa,
    });
  }
}
