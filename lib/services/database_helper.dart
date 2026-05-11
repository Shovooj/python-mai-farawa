import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// Local SQLite database helper.
// Responsible for DB creation and schema migrations. Important tables:
// - `local_progress`: stores progress locally for offline-first behavior.
// - `sync_queue`: stores pending operations to sync with remote firestore.
// - `downloaded_lessons`: tracks lessons and offline video download status.
// Migrations are applied in `_upgradeDB` based on the oldVersion value.
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
      version: 12,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Apply incremental schema changes when upgrading from older versions.
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
      await db.execute('''
    ALTER TABLE practices ADD COLUMN practiceOrder INTEGER NOT NULL DEFAULT 0
  ''');
    }

    if (oldVersion < 7) {
      await db.execute('''
    CREATE TABLE IF NOT EXISTS downloaded_lessons(
      lessonId TEXT PRIMARY KEY,
      isDownloaded INTEGER NOT NULL DEFAULT 0,
      videoDownloaded INTEGER NOT NULL DEFAULT 0,
      downloadedAt TEXT,
      updatedAt TEXT
    )
  ''');
    }

    if (oldVersion < 8) {
      await db.execute('ALTER TABLE questions ADD COLUMN questionTextHa TEXT');
      await db.execute('ALTER TABLE questions ADD COLUMN optionAHa TEXT');
      await db.execute('ALTER TABLE questions ADD COLUMN optionBHa TEXT');
      await db.execute('ALTER TABLE questions ADD COLUMN optionCHa TEXT');
      await db.execute('ALTER TABLE questions ADD COLUMN optionDHa TEXT');
    }

    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS local_progress(
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
    }

    if (oldVersion < 10) {
      await db.execute('ALTER TABLE practices ADD COLUMN titleHa TEXT');
      await db.execute('ALTER TABLE practices ADD COLUMN instructionHa TEXT');
      await db.execute(
        'ALTER TABLE practices ADD COLUMN expectedOutputHa TEXT',
      );
    }

    if (oldVersion < 11) {
      await db.execute('ALTER TABLE quizzes ADD COLUMN titleHa TEXT');
    }

    if (oldVersion < 12) {
      await db.execute('ALTER TABLE downloaded_lessons ADD COLUMN userId TEXT');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Create core tables used by the app. Keep schema changes backward compatible
    // where possible so old devices can upgrade smoothly.
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
        titleHa TEXT,
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
        questionTextHa TEXT,
        optionA TEXT NOT NULL,
        optionAHa TEXT,
        optionB TEXT NOT NULL,
        optionBHa TEXT,
        optionC TEXT NOT NULL,
        optionCHa TEXT,
        optionD TEXT NOT NULL,
        optionDHa TEXT,
        correctAnswer TEXT NOT NULL,
        "order" INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE practices(
        practiceId TEXT PRIMARY KEY,
        lessonId TEXT NOT NULL,
        title TEXT NOT NULL,
        titleHa TEXT,
        instruction TEXT NOT NULL,
        instructionHa TEXT,
        starterCode TEXT NOT NULL,
        expectedOutput TEXT NOT NULL,
        expectedOutputHa TEXT,
        practiceOrder INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE downloaded_lessons (
        userId TEXT NOT NULL,
        lessonId TEXT NOT NULL,
        isDownloaded INTEGER NOT NULL DEFAULT 0,
        videoDownloaded INTEGER NOT NULL DEFAULT 0,
        downloadedAt TEXT,
        updatedAt TEXT,
        PRIMARY KEY (userId, lessonId)
      )
    ''');
  }
}
