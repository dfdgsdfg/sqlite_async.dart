import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:sqlite_async/sqlite3_common.dart';
import 'package:sqlite_async/sqlite_async.dart';
import 'package:sqlite3/open.dart' as sqlite_open;

import 'abstract_test_utils.dart';

const defaultSqlitePath = '/opt/homebrew/opt/sqlite/lib/libsqlite3.dylib';

class TestSqliteOpenFactory extends TestDefaultSqliteOpenFactory {
  TestSqliteOpenFactory(
      {required super.path,
      super.sqliteOptions,
      super.sqlitePath = defaultSqlitePath,
      initStatements});

  @override
  CommonDatabase open(SqliteOpenOptions options) {
    sqlite_open.open.overrideFor(sqlite_open.OperatingSystem.macOS, () {
      return DynamicLibrary.open(sqlitePath);
    });
    final db = super.open(options);

    db.createFunction(
      functionName: 'test_sleep',
      argumentCount: const AllowedArgumentCount(1),
      function: (args) {
        final millis = args[0] as int;
        sleep(Duration(milliseconds: millis));
        return millis;
      },
    );

    db.createFunction(
      functionName: 'test_connection_name',
      argumentCount: const AllowedArgumentCount(0),
      function: (args) {
        return Isolate.current.debugName;
      },
    );

    return db;
  }
}

class TestUtils extends AbstractTestUtils {
  @override
  String dbPath() {
    Directory("test-db").createSync(recursive: false);
    return super.dbPath();
  }

  @override
  Future<void> cleanDb({required String path}) async {
    try {
      await File(path).delete();
    } on PathNotFoundException {
      // Not an issue
    }
    try {
      await File("$path-shm").delete();
    } on PathNotFoundException {
      // Not an issue
    }
    try {
      await File("$path-wal").delete();
    } on PathNotFoundException {
      // Not an issue
    }
  }

  @override
  List<String> findSqliteLibraries() {
    var glob = Glob('sqlite-*/.libs/libsqlite3.dylib');
    List<String> sqlites = [
      'libsqlite3.dylib',
      for (var sqlite in glob.listSync()) sqlite.path
    ];
    return sqlites;
  }

  @override
  Future<TestDefaultSqliteOpenFactory> testFactory(
      {String? path,
      String sqlitePath = defaultSqlitePath,
      List<String> initStatements = const [],
      SqliteOptions options = const SqliteOptions.defaults()}) async {
    return TestSqliteOpenFactory(
        path: path ?? dbPath(),
        sqlitePath: sqlitePath,
        sqliteOptions: options,
        initStatements: initStatements);
  }
}
