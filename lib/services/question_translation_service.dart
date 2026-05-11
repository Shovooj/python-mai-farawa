import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_config.dart';
import 'google_translate_service.dart';

// Translates question text and options to Hausa when missing. Each field is
// checked individually so existing translations aren't overwritten.
class QuestionTranslationService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> translateQuestionToHausa({
    required String questionId,
    required String questionText,
    required String optionA,
    required String optionB,
    required String optionC,
    required String optionD,
    String? questionTextHa,
    String? optionAHa,
    String? optionBHa,
    String? optionCHa,
    String? optionDHa,
  }) async {
    final translator = GoogleTranslateService(
      apiKey: AppConfig.googleTranslateApiKey,
    );

    final needsQuestionText = (questionTextHa ?? '').trim().isEmpty;
    final needsOptionA = (optionAHa ?? '').trim().isEmpty;
    final needsOptionB = (optionBHa ?? '').trim().isEmpty;
    final needsOptionC = (optionCHa ?? '').trim().isEmpty;
    final needsOptionD = (optionDHa ?? '').trim().isEmpty;

    if (!needsQuestionText &&
        !needsOptionA &&
        !needsOptionB &&
        !needsOptionC &&
        !needsOptionD) {
      return;
    }

    String newQuestionTextHa = questionTextHa ?? '';
    String newOptionAHa = optionAHa ?? '';
    String newOptionBHa = optionBHa ?? '';
    String newOptionCHa = optionCHa ?? '';
    String newOptionDHa = optionDHa ?? '';

    if (needsQuestionText) {
      newQuestionTextHa = await translator.translateText(text: questionText);
    }
    if (needsOptionA) {
      newOptionAHa = await translator.translateText(text: optionA);
    }
    if (needsOptionB) {
      newOptionBHa = await translator.translateText(text: optionB);
    }
    if (needsOptionC) {
      newOptionCHa = await translator.translateText(text: optionC);
    }
    if (needsOptionD) {
      newOptionDHa = await translator.translateText(text: optionD);
    }

    await firestore.collection('questions').doc(questionId).update({
      'questionTextHa': newQuestionTextHa,
      'optionAHa': newOptionAHa,
      'optionBHa': newOptionBHa,
      'optionCHa': newOptionCHa,
      'optionDHa': newOptionDHa,
    });
  }
}
