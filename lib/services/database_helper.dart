import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('python_mai_farawa.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
      CREATE TABLE IF NOT EXISTS quizzes(
        quizId TEXT PRIMARY KEY,
        lessonId TEXT NOT NULL,
        title TEXT NOT NULL,
        passingScore INTEGER NOT NULL,
        totalQuestions INTEGER NOT NULL
      )
    ''');

      await db.execute('''
      CREATE TABLE IF NOT EXISTS questions(
        questionId TEXT PRIMARY KEY,
        quizId TEXT NOT NULL,
        lessonId TEXT NOT NULL,
        questionText TEXT NOT NULL,
        optionA TEXT NOT NULL,
        optionB TEXT NOT NULL,
        optionC TEXT NOT NULL,
        optionD TEXT NOT NULL,
        correctAnswer TEXT NOT NULL,
        "order" INTEGER NOT NULL
      )
    ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
    CREATE TABLE IF NOT EXISTS practices(
      practiceId TEXT PRIMARY KEY,
      lessonId TEXT NOT NULL,
      title TEXT NOT NULL,
      instruction TEXT NOT NULL,
      starterCode TEXT NOT NULL,
      expectedOutput TEXT NOT NULL,
      practiceOrder INTEGER NOT NULL DEFAULT 0
    )
  ''');
    }

    if (oldVersion < 4) {
      // If an old practices table exists without the column, add it
      await db.execute('''
    ALTER TABLE practices ADD COLUMN practiceOrder INTEGER NOT NULL DEFAULT 0
  ''');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE lessons (
        lessonId TEXT PRIMARY KEY,
        lessonNumber INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        contentBody TEXT,
        durationMinutes INTEGER NOT NULL DEFAULT 0,
        videoUrl TEXT,
        isPublished INTEGER NOT NULL DEFAULT 1,
        updatedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE progress (
        progressId TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        lessonId TEXT NOT NULL,
        videoViewed INTEGER NOT NULL DEFAULT 0,
        quizCompleted INTEGER NOT NULL DEFAULT 0,
        practiceCompleted INTEGER NOT NULL DEFAULT 0,
        lessonCompleted INTEGER NOT NULL DEFAULT 0,
        score INTEGER NOT NULL DEFAULT 0,
        videoPositionSeconds INTEGER NOT NULL DEFAULT 0,
        videoDurationSeconds INTEGER NOT NULL DEFAULT 0,
        updatedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE local_progress(
        progressId TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        lessonId TEXT NOT NULL,
        lessonCompleted INTEGER NOT NULL DEFAULT 0,
        practiceCompleted INTEGER NOT NULL DEFAULT 0,
        quizCompleted INTEGER NOT NULL DEFAULT 0,
        videoViewed INTEGER NOT NULL DEFAULT 0,
        score INTEGER NOT NULL DEFAULT 0,
        videoPositionSeconds INTEGER NOT NULL DEFAULT 0,
        videoDurationSeconds INTEGER NOT NULL DEFAULT 0,
        updatedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entityType TEXT NOT NULL,
        entityId TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE quizzes(
        quizId TEXT PRIMARY KEY,
        lessonId TEXT NOT NULL,
        title TEXT NOT NULL,
        passingScore INTEGER NOT NULL,
        totalQuestions INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE questions(
        questionId TEXT PRIMARY KEY,
        quizId TEXT NOT NULL,
        lessonId TEXT NOT NULL,
        questionText TEXT NOT NULL,
        optionA TEXT NOT NULL,
        optionB TEXT NOT NULL,
        optionC TEXT NOT NULL,
        optionD TEXT NOT NULL,
        correctAnswer TEXT NOT NULL,
        "order" INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE practices(
        practiceId TEXT PRIMARY KEY,
        lessonId TEXT NOT NULL,
        title TEXT NOT NULL,
        instruction TEXT NOT NULL,
        starterCode TEXT NOT NULL,
        expectedOutput TEXT NOT NULL,
        practiceOrder INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }
}
