import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'pharmacy_unit.db');
    return openDatabase(
      path,
      version: 8,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        uid TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        role TEXT NOT NULL,
        profession TEXT,
        organization TEXT,
        address TEXT,
        about TEXT,
        fcm_token TEXT,
        photo_path TEXT,
        signature_path TEXT,
        specialty TEXT,
        practice_type TEXT,
        license_no TEXT,
        experience INTEGER,
        created_at INTEGER NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        unit TEXT NOT NULL,
        price REAL NOT NULL,
        supplier_id TEXT,
        image_path TEXT
      )''');
    await db.execute('''
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        user_name TEXT NOT NULL,
        supplier_id TEXT NOT NULL,
        supplier_name TEXT NOT NULL,
        status TEXT NOT NULL,
        total REAL NOT NULL,
        notes TEXT,
        created_at INTEGER NOT NULL,
        delivered_at INTEGER
      )''');
    await db.execute('''
      CREATE TABLE order_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        price REAL NOT NULL,
        qty INTEGER NOT NULL,
        FOREIGN KEY(order_id) REFERENCES orders(id) ON DELETE CASCADE
      )''');
    await db.execute('''
      CREATE TABLE supply_requests(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        user_name TEXT NOT NULL,
        name TEXT NOT NULL,
        details TEXT,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )''');
    await _createSupplyChanges(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // v3: no demo data.
      await db.delete('users', where: "uid LIKE 'seed_%'");
    }
    if (oldVersion < 4) {
      // v4: supplies belong to the supplier and go through admin approval.
      await db.delete('products', where: 'supplier_id IS NOT NULL');
      await _createSupplyChanges(db);
    }
    if (oldVersion < 5) {
      // v5: product photos.
      await _addColumnIfMissing(db, 'products', 'image_path', 'TEXT');
      await _addColumnIfMissing(db, 'supply_changes', 'image_path', 'TEXT');
    }
    if (oldVersion < 6) {
      // v6: profile photos.
      await _addColumnIfMissing(db, 'users', 'photo_path', 'TEXT');
    }
    if (oldVersion < 7) {
      // v7: professional details for doctors / pharmacists.
      await _addColumnIfMissing(db, 'users', 'specialty', 'TEXT');
      await _addColumnIfMissing(db, 'users', 'practice_type', 'TEXT');
      await _addColumnIfMissing(db, 'users', 'license_no', 'TEXT');
      await _addColumnIfMissing(db, 'users', 'experience', 'INTEGER');
    }
    if (oldVersion < 8) {
      // v8: supplier signature for invoices.
      await _addColumnIfMissing(db, 'users', 'signature_path', 'TEXT');
    }
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String type,
  ) async {
    final cols = await db.rawQuery('PRAGMA table_info($table)');
    if (cols.any((c) => c['name'] == column)) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
  }

  Future<void> _createSupplyChanges(Database db) => db.execute('''
      CREATE TABLE IF NOT EXISTS supply_changes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplier_id TEXT NOT NULL,
        supplier_name TEXT NOT NULL,
        action TEXT NOT NULL,
        product_id INTEGER,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        unit TEXT NOT NULL,
        price REAL NOT NULL,
        old_name TEXT,
        old_category TEXT,
        old_unit TEXT,
        old_price REAL,
        image_path TEXT,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )''');
}
