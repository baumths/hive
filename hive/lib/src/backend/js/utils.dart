import 'dart:async' show Completer;
import 'dart:js_interop';

import 'package:hive/hive.dart' show HiveError;
import 'package:web/web.dart' as web;

extension IdbRequestUnwrapper on web.IDBRequest {
  Future<T?> unwrap<T extends JSAny?>() {
    final completer = Completer<T?>();
    onsuccess = (web.Event? _) {
      completer.complete(result as T?);
    }.toJS;
    onerror = (web.Event? _) {
      completer.complete(null);
    }.toJS;
    return completer.future;
  }
}

extension IdbOpenDbRequestUnwrapper on web.IDBOpenDBRequest {
  Future<web.IDBDatabase> unwrap({
    void Function(web.IDBDatabase db)? onUpgradeNeeded,
  }) {
    final completer = Completer<web.IDBDatabase>();
    onupgradeneeded = (JSAny? _) {
      onUpgradeNeeded?.call(result as web.IDBDatabase);
    }.toJS;
    onsuccess = (JSAny? _) {
      completer.complete(result as web.IDBDatabase);
    }.toJS;
    onblocked = (JSAny? _) {
      completer.completeError(HiveError(error?.message ?? 'idb open blocked'));
    }.toJS;
    onerror = (JSAny? _) {
      completer.completeError(HiveError(error?.message ?? 'idb open error'));
    }.toJS;
    return completer.future;
  }
}
