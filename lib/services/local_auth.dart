import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

// Jalankan PBKDF2 di isolate agar tampilan tetap responsif.
Future<List<int>> _deriveHash((String, List<int>) input) async {
  final algorithm = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 600000,
    bits: 256,
  );
  final key = await algorithm.deriveKey(
    secretKey: SecretKey(utf8.encode(input.$1)),
    nonce: input.$2,
  );
  return key.extractBytes();
}

class LocalAuth {
  Future<bool> register(String email, String password) async {
    final random = Random.secure();
    final salt = Uint8List.fromList(
      List.generate(16, (_) => random.nextInt(256)),
    );
    final hash = await compute(_deriveHash, (password, salt));
    final db = await AppDatabase.instance.database;
    try {
      await db.insert('users', {
        'email': email.trim().toLowerCase(),
        'salt': base64Encode(salt),
        'password_hash': base64Encode(hash),
      });
      return true;
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) return false;
      rethrow;
    }
  }

  Future<int?> login(String email, String password) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    final expected = base64Decode(row['password_hash'] as String);
    final actual = await compute(_deriveHash, (
      password,
      base64Decode(row['salt'] as String),
    ));

    // Bandingkan seluruh byte sebelum memutuskan hasil login.
    var difference = expected.length ^ actual.length;
    for (var i = 0; i < expected.length && i < actual.length; i++) {
      difference |= expected[i] ^ actual[i];
    }
    return difference == 0 ? row['id'] as int : null;
  }
}
