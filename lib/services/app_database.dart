import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  Database? _database;
  int? userId;

  int get activeUserId => userId ?? (throw StateError('Silakan masuk dulu.'));

  static Future<void> _addAccounts(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        salt TEXT NOT NULL,
        password_hash TEXT NOT NULL
      )
    ''');
    // Baris lama tetap tersimpan dengan user_id NULL.
    await db.execute(
      'ALTER TABLE orders ADD COLUMN user_id INTEGER REFERENCES users(id)',
    );
    await db.execute(
      'ALTER TABLE orders ADD COLUMN demo_paid INTEGER NOT NULL DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE cart_items ADD COLUMN user_id INTEGER REFERENCES users(id)',
    );
    await db.execute('ALTER TABLE favorites RENAME TO legacy_favorites');
    await db.execute('''
      CREATE TABLE favorites (
        user_id INTEGER NOT NULL REFERENCES users(id),
        menu_id TEXT NOT NULL,
        PRIMARY KEY (user_id, menu_id)
      )
    ''');
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    final String databasePath;
    if (Platform.isWindows || Platform.isLinux) {
      final appSupportDirectory = await getApplicationSupportDirectory();
      final databaseDirectory = Directory(
        p.join(appSupportDirectory.path, 'databases'),
      );
      await databaseDirectory.create(recursive: true);
      databasePath = p.join(databaseDirectory.path, 'seafood_order.db');
    } else {
      final databasesPath = await getDatabasesPath();
      databasePath = p.join(databasesPath, 'seafood_order.db');
    }
    _database = await openDatabase(
      databasePath,
      version: 4,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE favorites (menu_id TEXT PRIMARY KEY)');
        await db.execute('''
          CREATE TABLE cart_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            menu_name TEXT NOT NULL,
            category TEXT NOT NULL,
            price INTEGER NOT NULL,
            description TEXT NOT NULL,
            image_url TEXT NOT NULL,
            options TEXT NOT NULL,
            note TEXT NOT NULL,
            quantity INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customer_name TEXT NOT NULL,
            phone TEXT NOT NULL,
            address TEXT NOT NULL,
            payment_method TEXT NOT NULL,
            delivery_date TEXT NOT NULL DEFAULT '',
            needs_cutlery INTEGER NOT NULL DEFAULT 0,
            pickup INTEGER NOT NULL DEFAULT 0,
            total INTEGER NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE order_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER NOT NULL,
            menu_name TEXT NOT NULL,
            price INTEGER NOT NULL,
            quantity INTEGER NOT NULL,
            options TEXT NOT NULL,
            note TEXT NOT NULL,
            FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
          )
        ''');
        await _addAccounts(db);
      },
      // Menambah detail checkout tanpa menghapus pesanan dari versi database lama.
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('CREATE TABLE favorites (menu_id TEXT PRIMARY KEY)');
          await db.execute(
            'ALTER TABLE orders ADD COLUMN pickup INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE orders ADD COLUMN delivery_date TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            'ALTER TABLE orders ADD COLUMN needs_cutlery INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 4) await _addAccounts(db);
      },
    );
    return _database!;
  }

  Future<List<Map<String, Object?>>> getCartItems(int accountId) async {
    final db = await database;
    return db.query(
      'cart_items',
      where: 'user_id = ?',
      whereArgs: [accountId],
      orderBy: 'id ASC',
    );
  }

  Future<void> replaceCartItems(
    int accountId,
    List<Map<String, Object?>> items,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'cart_items',
        where: 'user_id = ?',
        whereArgs: [accountId],
      );
      for (final item in items) {
        await txn.insert('cart_items', {...item, 'user_id': accountId});
      }
    });
  }

  Future<Set<String>> getFavorites() async {
    final accountId = activeUserId;
    final db = await database;
    final rows = await db.query(
      'favorites',
      where: 'user_id = ?',
      whereArgs: [accountId],
    );
    return rows.map((row) => row['menu_id'] as String).toSet();
  }

  Future<void> setFavorite(String id, bool selected) async {
    final accountId = activeUserId;
    final db = await database;
    if (selected) {
      await db.insert('favorites', {
        'menu_id': id,
        'user_id': accountId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    } else {
      await db.delete(
        'favorites',
        where: 'user_id = ? AND menu_id = ?',
        whereArgs: [accountId, id],
      );
    }
  }

  Future<int> saveOrder({
    required String customerName,
    required String phone,
    required String address,
    required String paymentMethod,
    required String deliveryDate,
    required bool needsCutlery,
    required bool pickup,
    required int total,
    required String createdAt,
    required List<Map<String, Object?>> items,
  }) async {
    final accountId = activeUserId;
    final db = await database;
    return db.transaction((txn) async {
      final orderId = await txn.insert('orders', {
        'user_id': accountId,
        'demo_paid': 1,
        'customer_name': customerName,
        'phone': phone,
        'address': address,
        'payment_method': paymentMethod,
        'delivery_date': deliveryDate,
        'needs_cutlery': needsCutlery ? 1 : 0,
        'pickup': pickup ? 1 : 0,
        'total': total,
        'created_at': createdAt,
      });

      for (final item in items) {
        await txn.insert('order_items', {
          'order_id': orderId,
          'menu_name': item['menu_name'],
          'price': item['price'],
          'quantity': item['quantity'],
          'options': item['options'],
          'note': item['note'],
        });
      }
      // Jika salah satu operasi gagal, SQLite membatalkan seluruh checkout.
      await txn.delete(
        'cart_items',
        where: 'user_id = ?',
        whereArgs: [accountId],
      );
      return orderId;
    });
  }

  Future<List<Map<String, Object?>>> getOrders() async {
    final accountId = activeUserId;
    final db = await database;
    final orders = await db.query(
      'orders',
      where: 'user_id = ?',
      whereArgs: [accountId],
      orderBy: 'id DESC',
    );
    final result = <Map<String, Object?>>[];

    for (final order in orders) {
      final items = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [order['id']],
        orderBy: 'id ASC',
      );
      result.add({...order, 'items': items});
    }
    return result;
  }
}
