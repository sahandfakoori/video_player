import 'dart:io';

import 'package:flutter_application_1/data/data_source/data_source.dart';
import 'package:flutter_application_1/data/data_source/data_source_impl.dart';
import 'package:flutter_application_1/domain/repository/repository.dart';

class RepositoryImpl implements Repository {
  final DataSource _dataSource = DataSourceImpl();
  @override
  Future<void> scanDirectoryRecursive(
    Directory dir,
    Map<String, List<File>> videosByFolder,
    List<String> deletePaths,
  ) async {
    _dataSource.scanDirectoryRecursive(dir, videosByFolder, deletePaths);
  }
}
