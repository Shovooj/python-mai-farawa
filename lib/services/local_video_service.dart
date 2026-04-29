import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class LocalVideoService {
  Future<Directory> _videoDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final videoDir = Directory(p.join(dir.path, 'lesson_videos'));

    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
    }

    return videoDir;
  }

  Future<String> getVideoFilePath(String lessonId) async {
    final videoDir = await _videoDirectory();
    return p.join(videoDir.path, '$lessonId.mp4');
  }

  Future<File?> getDownloadedVideoFile(String lessonId) async {
    final filePath = await getVideoFilePath(lessonId);
    final file = File(filePath);

    if (await file.exists()) {
      return file;
    }

    return null;
  }

  Future<File> downloadVideo({
    required String lessonId,
    required String videoUrl,
  }) async {
    final filePath = await getVideoFilePath(lessonId);
    final response = await http.get(Uri.parse(videoUrl));

    if (response.statusCode != 200) {
      throw Exception('Failed to download video.');
    }

    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file;
  }

  Future<bool> isVideoDownloaded(String lessonId) async {
    final file = await getDownloadedVideoFile(lessonId);
    return file != null;
  }

  Future<void> deleteVideo(String lessonId) async {
    final file = await getDownloadedVideoFile(lessonId);
    if (file != null && await file.exists()) {
      await file.delete();
    }
  }
}
