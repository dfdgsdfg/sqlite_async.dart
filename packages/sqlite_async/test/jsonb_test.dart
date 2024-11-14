import 'dart:convert';

import 'package:sqlite_async/sqlite_async.dart';
import 'package:test/test.dart';

import 'utils/test_utils_impl.dart';

final testUtils = TestUtils();

class TestUser {
  int? id;
  String? name;
  String? email;

  TestUser({this.id, this.name, this.email});

  factory TestUser.fromMap(Map<String, dynamic> data) {
    return TestUser(id: data['id'], name: data['name'], email: data['email']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email};
  }
}

void main() {
  group('jsonb Tests', () {
    late String path;

    setUp(() async {
      path = testUtils.dbPath();
      await testUtils.cleanDb(path: path);
    });

    tearDown(() async {
      await testUtils.cleanDb(path: path);
    });

    createTables(SqliteDatabase db) async {
      await db.writeTransaction((tx) async {
        await tx.execute(
            'CREATE TABLE users_json(id INTEGER PRIMARY KEY AUTOINCREMENT, json TEXT)');
        await tx.execute(
            'CREATE TABLE users_jsonb(id INTEGER PRIMARY KEY AUTOINCREMENT, jsonb BLOB)');
      });
    }

    test('Inserts as json', () async {
      final factory = await testUtils.testFactory();
      final db = SqliteDatabase.withFactory(factory);
      await db.initialize();

      await createTables(db);
      final user = TestUser(id: 1, name: 'Bob', email: 'bob@example.org');

      await db.execute("INSERT INTO users_json(json) VALUES (json(?))",
          [jsonEncode(user.toJson())]);

      final result = await db.getOptional(
          "SELECT json FROM users_json WHERE id = ? ORDER BY id", [1]);
      final jsonString = result?['json'];
      final userFromDb = TestUser.fromMap(jsonDecode(jsonString!));

      expect(userFromDb.name, equals('Bob'));
    });

    test('Inserts as binary', () async {
      final factory = await testUtils.testFactory();
      final db = SqliteDatabase.withFactory(factory);
      await db.initialize();

      await createTables(db);
      final user = TestUser(id: 1, name: 'Bob', email: 'bob@example.org');

      await db.execute("INSERT INTO users_jsonb(jsonb) VALUES (jsonb(?))",
          [jsonEncode(user.toJson())]);

      final result = await db.getOptional(
          "SELECT json(jsonb) FROM users_jsonb WHERE id = ? ORDER BY id", [1]);
      final jsonString = result?['json(jsonb)'];
      final userFromDb = TestUser.fromMap(jsonDecode(jsonString!));

      expect(userFromDb.name, equals('Bob'));
    });
  });
}

// For some reason, future.ignore() doesn't actually ignore errors in these tests.
void ignore(Future future) {
  future.then((_) {}, onError: (_) {});
}
