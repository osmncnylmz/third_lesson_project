import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton yapı
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  // Veritabanını başlatır ve oluşturma işlemlerini tanımlar.
  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'gezilecek_yerler.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      // onUpgrade: _onUpgrade,
    );
  }

  // Veritabanı ilk oluşturulduğunda tabloları tanımlar.
  Future<void> _onCreate(Database db, int version) async {
    // users tablosu
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT
      )
    ''');

    // places tablosu; image_path sütunu ile fotoğraf dosya yolu saklanır.
    await db.execute('''
      CREATE TABLE places (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        name TEXT NOT NULL,
        description TEXT,
        visit_status TEXT CHECK(visit_status IN ('gezdim', 'gezmek istiyorum')),
        planned_date TEXT,
        comment TEXT,
        image_path TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');
  }

  // Kullanıcı ekleme (örnek)
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  // Yeni yer ekleme
  Future<int> insertPlace(Map<String, dynamic> place) async {
    final db = await database;
    return await db.insert('places', place);
  }

  // Yerleri listeleme; isteğe bağlı olarak ziyaret durumuna göre filtre uygulanır.
  Future<List<Map<String, dynamic>>> getPlaces({String? filter}) async {
    final db = await database;
    if (filter == null || filter.isEmpty) {
      return await db.query('places');
    } else {
      return await db.query(
        'places',
        where: 'visit_status = ?',
        whereArgs: [filter],
      );
    }
  }

  // Yer güncelleme
  Future<int> updatePlace(Map<String, dynamic> place, int id) async {
    final db = await database;
    return await db.update('places', place, where: 'id = ?', whereArgs: [id]);
  }

  // Yer silme
  Future<int> deletePlace(int id) async {
    final db = await database;
    return await db.delete('places', where: 'id = ?', whereArgs: [id]);
  }
}
