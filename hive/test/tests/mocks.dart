library hive.test.mocks;

import 'dart:io';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:hive/src/io/frame_io_helper.dart';
import 'package:hive/src/object/hive_list_impl.dart';
import 'package:mockito/annotations.dart';

export 'mocks.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<Box>(),
  MockSpec<ChangeNotifier>(),
  MockSpec<StorageBackend>(),
  MockSpec<Keystore>(),
  MockSpec<HiveImpl>(),
  MockSpec<HiveList>(),
  MockSpec<HiveListImpl>(),
  MockSpec<RandomAccessFile>(),
  MockSpec<BinaryReader>(),
  MockSpec<BinaryWriter>(),
  MockSpec<File>(),
  MockSpec<FrameIoHelper>(),
])
// ignore: prefer_typing_uninitialized_variables, unused_element
var _mocks;

class TestHiveObject extends HiveObject {}
