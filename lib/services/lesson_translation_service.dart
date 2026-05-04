import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_config.dart';
import 'google_translate_service.dart';

class LessonTranslationService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> translateLessonToHausa({
    required String lessonId,
    required String title,
    required String description,
    String? titleHa,
    String? descriptionHa,
  }) async {
    final translator = GoogleTranslateService(
      apiKey: AppConfig.googleTranslateApiKey,
    );

    final needsTitleTranslation = (titleHa ?? '').trim().isEmpty;
    final needsDescriptionTranslation = (descriptionHa ?? '').trim().isEmpty;

    if (!needsTitleTranslation && !needsDescriptionTranslation) {
      return;
    }

    String newTitleHa = titleHa ?? '';
    String newDescriptionHa = descriptionHa ?? '';

    if (needsTitleTranslation) {
      newTitleHa = await translator.translateText(text: title);
    }

    if (needsDescriptionTranslation) {
      newDescriptionHa = await translator.translateText(text: description);
    }

    await firestore.collection('lessons').doc(lessonId).update({
      'titleHa': newTitleHa,
      'descriptionHa': newDescriptionHa,
    });
  }
}
