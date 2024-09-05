import 'dart:async';
import 'dart:js_interop';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/js/storage_backend_js.dart';
import 'package:hive/src/backend/js/utils.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:web/web.dart' as web;

/// Opens IndexedDB databases
class BackendManager implements BackendManagerInterface {
  @override
  Future<StorageBackend> open(
    String name,
    String? path,
    bool crashRecovery,
    HiveCipher? cipher,
  ) async {
    final db = await web.window.indexedDB.open(name, 1).unwrap(
      onUpgradeNeeded: (web.IDBDatabase db) {
        if (!db.objectStoreNames.contains('box')) {
          db.createObjectStore('box');
        }
      },
    );
    return StorageBackendJs(db, cipher);
  }

  @override
  Future<void> deleteBox(String name, String? path) {
    return web.window.indexedDB.deleteDatabase(name).unwrap();
  }

  @override
  Future<bool> boxExists(String name, String? path) async {
    // https://stackoverflow.com/a/17473952
    try {
      var completer = Completer<bool>();
      var request = web.window.indexedDB.open(name, 1);
      request
        ..onupgradeneeded = (web.Event _) {
          request.transaction?.abort();
          completer.complete(false);
        }.toJS
        ..onsuccess = (web.Event _) {
          request.transaction?.abort();
          completer.complete(true);
        }.toJS
        ..onblocked = (web.Event _) {
          request.transaction?.abort();
          completer.complete(true);
        }.toJS
        ..onerror = (web.Event _) {
          request.transaction?.abort();
          completer.complete(true);
        }.toJS;
      return await completer.future;
    } catch (error) {
      return false;
    }
  }
}
