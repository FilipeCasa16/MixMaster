import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'models.dart';

class LocalAccount {
  const LocalAccount({required this.id, required this.email});

  final int id;
  final String email;

  String get displayName {
    final localPart = email
        .split('@')
        .first
        .replaceAll(RegExp(r'[._+-]+'), ' ');
    return localPart
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class AccountException implements Exception {
  const AccountException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();
  static const _databaseName = 'mixmaster.db';
  static const _passwordIterations = 120000;
  static final _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _passwordIterations,
    bits: 256,
  );

  Database? _database;

  Future<Database> get database async {
    final current = _database;
    if (current != null) return current;

    final databasesPath = await getDatabasesPath();
    final db = await openDatabase(
      path.join(databasesPath, _databaseName),
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE accounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL COLLATE NOCASE UNIQUE,
            password_salt TEXT NOT NULL,
            password_hash TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await database.execute('''
          CREATE TABLE app_session (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            account_id INTEGER NOT NULL,
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
          )
        ''');
        await database.execute('''
          CREATE TABLE favorites (
            account_id INTEGER NOT NULL,
            drink_id TEXT NOT NULL,
            drink_json TEXT NOT NULL,
            favorited_at TEXT NOT NULL,
            PRIMARY KEY (account_id, drink_id),
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
          )
        ''');
      },
    );
    await db.execute('PRAGMA foreign_keys = ON');
    _database = db;
    return db;
  }

  Future<LocalAccount?> getCurrentAccount() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT accounts.id, accounts.email
      FROM app_session
      JOIN accounts ON accounts.id = app_session.account_id
      WHERE app_session.id = 1
    ''');
    if (rows.isEmpty) return null;
    return LocalAccount(
      id: rows.first['id'] as int,
      email: rows.first['email'] as String,
    );
  }

  Future<LocalAccount> register(String email, String password) async {
    final db = await database;
    final salt = _secureRandomBytes(16);
    final hash = await _hashPassword(password, salt);
    try {
      return await db.transaction((transaction) async {
        final id = await transaction.insert('accounts', {
          'email': email.trim().toLowerCase(),
          'password_salt': base64Encode(salt),
          'password_hash': base64Encode(hash),
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
        await _saveSession(transaction, id);
        return LocalAccount(id: id, email: email.trim().toLowerCase());
      });
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw const AccountException('Este e-mail já está cadastrado.');
      }
      rethrow;
    }
  }

  Future<LocalAccount> login(String email, String password) async {
    final db = await database;
    final rows = await db.query(
      'accounts',
      columns: ['id', 'email', 'password_salt', 'password_hash'],
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw const AccountException('E-mail ou senha inválidos.');
    }
    final row = rows.first;
    final salt = base64Decode(row['password_salt'] as String);
    final expectedHash = base64Decode(row['password_hash'] as String);
    final actualHash = await _hashPassword(password, salt);
    if (!_constantTimeEquals(expectedHash, actualHash)) {
      throw const AccountException('E-mail ou senha inválidos.');
    }

    final accountId = row['id'] as int;
    await db.transaction((transaction) => _saveSession(transaction, accountId));
    return LocalAccount(id: accountId, email: row['email'] as String);
  }

  Future<void> logout() async {
    final db = await database;
    await db.delete('app_session', where: 'id = 1');
  }

  Future<List<Drink>> getFavorites(int accountId) async {
    final db = await database;
    final rows = await db.query(
      'favorites',
      columns: ['drink_json'],
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'favorited_at DESC',
    );
    return rows
        .map(
          (row) => Drink.fromJson(
            jsonDecode(row['drink_json'] as String) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> setFavorite(int accountId, Drink drink, bool isFavorite) async {
    final db = await database;
    if (!isFavorite) {
      await db.delete(
        'favorites',
        where: 'account_id = ? AND drink_id = ?',
        whereArgs: [accountId, drink.id],
      );
      return;
    }
    await db.insert('favorites', {
      'account_id': accountId,
      'drink_id': drink.id,
      'drink_json': jsonEncode(_drinkToJson(drink)),
      'favorited_at': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _saveSession(Transaction transaction, int accountId) async {
    await transaction.insert('app_session', {
      'id': 1,
      'account_id': accountId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<int>> _hashPassword(String password, List<int> salt) async {
    final key = await _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    return key.extractBytes();
  }

  List<int> _secureRandomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  bool _constantTimeEquals(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var index = 0; index < left.length; index++) {
      difference |= left[index] ^ right[index];
    }
    return difference == 0;
  }

  Map<String, dynamic> _drinkToJson(Drink drink) {
    final json = <String, dynamic>{
      'idDrink': drink.id,
      'strDrink': drink.name,
      'strDrinkThumb': drink.thumb,
      'strCategory': drink.category,
      'strAlcoholic': drink.alcoholic,
      'strGlass': drink.glass,
      if (drink.instructions != null) 'strInstructions': drink.instructions,
    };
    for (var index = 0; index < drink.ingredients.length; index++) {
      final ingredient = drink.ingredients[index];
      json['strIngredient${index + 1}'] = ingredient.name;
      json['strMeasure${index + 1}'] = ingredient.measure;
    }
    return json;
  }
}
