export 'stub_sqlite_database.dart'
    // ignore: uri_does_not_exist
    if (dart.library.io) '../native/database/native_sqlite_database.dart'
    // ignore: uri_does_not_exist
    if (dart.library.js_interop) '../web/database/web_sqlite_database.dart';
