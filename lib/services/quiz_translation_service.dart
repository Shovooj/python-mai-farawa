import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_config.dart';
import 'google_translate_service.dart';

class QuizTranslationService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> translateQuizToHausa({
    required String quizId,
    required String title,
    String? titleHa,
  }) async {
    final translator = GoogleTranslateService(
      apiKey: AppConfig.googleTranslateApiKey,
    );

    final needsTitleTranslation = (titleHa ?? '').trim().isEmpty;

    if (!needsTitleTranslation) return;

    String newTitleHa = titleHa ?? '';

    if (needsTitleTranslation) {
      newTitleHa = await translator.translateText(text: title);
    }

    await firestore.collection('quizzes').doc(quizId).update({
      'titleHa': newTitleHa,
    });
  }
}
