import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:meta/meta.dart';
import 'package:web/web.dart' as web;

import 'utils.dart';

/// Handles all IndexedDB related tasks
class StorageBackendJs extends StorageBackend {
  static const _bytePrefix = [0x90, 0xA9];
  final web.IDBDatabase _db;
  final HiveCipher? _cipher;

  TypeRegistry _registry;

  /// Not part of public API
  StorageBackendJs(this._db, this._cipher,
      [this._registry = TypeRegistryImpl.nullImpl]);

  @override
  String? get path => null;

  @override
  bool supportsCompaction = false;

  bool _isEncoded(Uint8List bytes) {
    return bytes.length >= _bytePrefix.length &&
        bytes[0] == _bytePrefix[0] &&
        bytes[1] == _bytePrefix[1];
  }

  /// Not part of public API
  @visibleForTesting
  Object? encodeValue(Frame frame) {
    var value = frame.value;
    if (_cipher == null) {
      if (value == null) {
        return value;
      } else if (value is Uint8List) {
        if (!_isEncoded(value)) {
          return value.buffer;
        }
      } else if (value is num ||
          value is bool ||
          value is String ||
          value is List<num> ||
          value is List<bool> ||
          value is List<String>) {
        return value;
      }
    }

    var frameWriter = BinaryWriterImpl(_registry);
    frameWriter.writeByteList(_bytePrefix, writeLength: false);

    if (_cipher == null) {
      frameWriter.write(value);
    } else {
      frameWriter.writeEncrypted(value, _cipher);
    }

    var bytes = frameWriter.toBytes();
    var sublist = bytes.sublist(0, bytes.length);
    return sublist.buffer;
  }

  /// Not part of public API
  @visibleForTesting
  Object? decodeValue(Object? value) {
    if (value is ByteBuffer) {
      var bytes = Uint8List.view(value);
      if (_isEncoded(bytes)) {
        var reader = BinaryReaderImpl(bytes, _registry);
        reader.skip(2);
        if (_cipher == null) {
          return reader.read();
        } else {
          return reader.readEncrypted(_cipher);
        }
      } else {
        return bytes;
      }
    } else {
      return value;
    }
  }

  /// Not part of public API
  @visibleForTesting
  web.IDBObjectStore getStore(bool write, [String box = 'box']) {
    return _db
        .transaction(box.toJS, write ? 'readwrite' : 'readonly')
        .objectStore(box);
  }

  /// Not part of public API
  @visibleForTesting
  Future<List<Object?>> getKeys() async {
    final result = await getStore(false).getAllKeys().unwrap<JSArray?>();
    return result?.toDart.map((e) => e.dartify()).toList() ?? [];
  }

  /// Not part of public API
  @visibleForTesting
  Future<Iterable<Object?>> getValues() async {
    final result = await getStore(false).getAll().unwrap<JSArray?>();
    return result?.toDart.map((e) => decodeValue(e.dartify())) ?? [];
  }

  @override
  Future<int> initialize(
      TypeRegistry registry, Keystore keystore, bool lazy) async {
    _registry = registry;
    var keys = await getKeys();
    if (!lazy) {
      var i = 0;
      var values = await getValues();
      for (var value in values) {
        var key = keys[i++];
        keystore.insert(Frame(key, value), notify: false);
      }
    } else {
      for (var key in keys) {
        keystore.insert(Frame.lazy(key), notify: false);
      }
    }

    return 0;
  }

  @override
  Future<Object?> readValue(Frame frame) async {
    Object? result;
    try {
      final request = getStore(false).get(frame.key.jsify());
      result = (await request.unwrap<JSObject?>()).dartify();
    } on HiveError {
      result = null;
    }
    return decodeValue(result);
  }

  @override
  Future<void> writeFrames(List<Frame> frames) async {
    var store = getStore(true);
    for (var frame in frames) {
      if (frame.deleted) {
        await store.delete(frame.key.jsify()).unwrap();
      } else {
        await store.put(encodeValue(frame).jsify(), frame.key.jsify()).unwrap();
      }
    }
  }

  @override
  Future<List<Frame>> compact(Iterable<Frame> frames) {
    throw UnsupportedError('Not supported');
  }

  @override
  Future<void> clear() async {
    await getStore(true).clear().unwrap();
  }

  @override
  Future<void> close() async {
    _db.close();
  }

  @override
  Future<void> deleteFromDisk() async {
    await web.window.indexedDB.deleteDatabase(_db.name).unwrap();
  }
}
