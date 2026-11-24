import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  Database? _database;

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
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
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
      },
      // Menambah detail checkout tanpa menghapus pesanan dari versi database lama.
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE orders ADD COLUMN delivery_date TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            'ALTER TABLE orders ADD COLUMN needs_cutlery INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
    );
    return _database!;
  }

  Future<List<Map<String, Object?>>> getCartItems() async {
    final db = await database;
    return db.query('cart_items', orderBy: 'id ASC');
  }

  Future<void> replaceCartItems(List<Map<String, Object?>> items) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('cart_items');
      for (final item in items) {
        await txn.insert('cart_items', item);
      }
    });
  }

  Future<int> saveOrder({
    required String customerName,
    required String phone,
    required String address,
    required String paymentMethod,
    required String deliveryDate,
    required bool needsCutlery,
    required int total,
    required List<Map<String, Object?>> items,
  }) async {
    final db = await database;
    return db.transaction((txn) async {
      final orderId = await txn.insert('orders', {
        'customer_name': customerName,
        'phone': phone,
        'address': address,
        'payment_method': paymentMethod,
        'delivery_date': deliveryDate,
        'needs_cutlery': needsCutlery ? 1 : 0,
        'total': total,
        'created_at': DateTime.now().toIso8601String(),
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
      await txn.delete('cart_items');
      return orderId;
    });
  }

  Future<List<Map<String, Object?>>> getOrders() async {
    final db = await database;
    final orders = await db.query('orders', orderBy: 'id DESC');
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
