import 'package:cloud_firestore/cloud_firestore.dart';
import 'google_translate_service.dart';

class ContentTranslationService {
  final FirebaseFirestore firestore;
  final GoogleTranslateService translator;

  ContentTranslationService({
    required this.firestore,
    required this.translator,
  });

  Future<void> translateLessonDocument(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;

    final String title = (data['title'] ?? '').toString();
    final String description = (data['description'] ?? '').toString();

    final String titleHa = (data['titleHa'] ?? '').toString();
    final String descriptionHa = (data['descriptionHa'] ?? '').toString();

    final Map<String, dynamic> updates = {};

    if (titleHa.trim().isEmpty && title.trim().isNotEmpty) {
      updates['titleHa'] = await translator.translateText(text: title);
    }

    if (descriptionHa.trim().isEmpty && description.trim().isNotEmpty) {
      updates['descriptionHa'] = await translator.translateText(
        text: description,
      );
    }

    if (updates.isNotEmpty) {
      await firestore.collection('lessons').doc(doc.id).update(updates);
    }
  }
}
