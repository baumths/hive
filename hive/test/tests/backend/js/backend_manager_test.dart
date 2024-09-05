@TestOn('browser')
library;

import 'package:hive/src/backend/js/backend_manager.dart';
import 'package:hive/src/backend/js/utils.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

Future<web.IDBDatabase> _openDb() async {
  return await web.window.indexedDB.open('testBox', 1).unwrap(
    onUpgradeNeeded: (db) {
      if (!db.objectStoreNames.contains('box')) {
        db.createObjectStore('box');
      }
    },
  );
}

void main() {
  group('BackendManager', () {
    group('.boxExists()', () {
      test('returns true', () async {
        var backendManager = BackendManager();
        var db = await _openDb();
        db.close();
        expect(await backendManager.boxExists('testBox', null), isTrue);
      });

      test('returns false', () async {
        var backendManager = BackendManager();
        var boxName = 'notexists-${DateTime.now().millisecondsSinceEpoch}';
        expect(await backendManager.boxExists(boxName, null), isFalse);
      });
    });
  });
}
