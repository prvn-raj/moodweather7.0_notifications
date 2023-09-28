import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final _databaseName = "MoodWeatherDatabase.db";
  static final _databaseVersion = 1;

  static final table = 'mood_history';

  static final columnId = '_id';
  static final columnMood = 'mood';
  static final columnWeather = 'weather';
  static final columnDate = 'date';

  // Singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY,
            $columnMood TEXT NOT NULL,
            $columnWeather TEXT NOT NULL,
            $columnDate TEXT NOT NULL
          )
          ''');
  }

  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  Future<void> cleanupMoods() async {
    Database db = await instance.database;
    DateTime ninetyDaysAgo = DateTime.now().subtract(Duration(days: 90));
    await db.delete(table, where: '$columnDate < ?', whereArgs: [ninetyDaysAgo.toIso8601String()]);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    return await db.query(table);
  }

  Future<List<Map<String, dynamic>>> queryLast90Days() async {
    Database db = await instance.database;
    DateTime ninetyDaysAgo = DateTime.now().subtract(Duration(days: 90));
    return await db.query(table, where: '$columnDate >= ?', whereArgs: [ninetyDaysAgo.toIso8601String()]);
  }

  Future<int> getMoodCountForDay(DateTime date) async {
    Database db = await instance.database;
    String dateStr = date.toIso8601String().split('T')[0];
    int? count = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM $table WHERE date LIKE "$dateStr%"'));
    return count ?? 0;
  }

  Future<void> deleteOldestMoodForDay(DateTime date) async {
    Database db = await instance.database;
    String dateStr = date.toIso8601String().split('T')[0];
    var result = await db.query(table,
        where: 'date LIKE ?', whereArgs: ["$dateStr%"], orderBy: 'date ASC', limit: 1);
    if (result.isNotEmpty) {
      await db.delete(table, where: '$columnId = ?', whereArgs: [result.first[columnId]]);
    }
  }
}
