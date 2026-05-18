import 'dart:io';

import 'package:flutter_application_1/data/data_source/data_source.dart';
import 'package:path/path.dart' as p;

class DataSourceImpl implements DataSource {
  @override
  Future<void> scanDirectoryRecursive(
    Directory dir,
    Map<String, List<File>> videosByFolder,
    List<String> deletePaths,
  ) async {
    try {
      final List<FileSystemEntity> entities = dir.listSync();

      for (var entity in entities) {
        if (entity is File) {
          final path = entity.path.toLowerCase();
          final fileName = entity.path.split('/').last.toLowerCase();
          final isVideo =
              path.endsWith('.mp4') ||
              path.endsWith('.mov') ||
              path.endsWith('.mkv');
          final isTemp =
              fileName.startsWith('>temp') || fileName.startsWith('temp');
          final isBigEnough = entity.lengthSync() > 1024 * 1024;

          if (isVideo &&
              !isTemp &&
              isBigEnough &&
              !deletePaths.contains(entity.path)) {
            final folderName = p.basename(dir.path);
            if (folderName.startsWith('.')) return;
            if (!videosByFolder.containsKey(folderName)) {
              videosByFolder[folderName] = [];
            }
            videosByFolder[folderName]!.add(entity);
          }
        } else if (entity is Directory) {
          await scanDirectoryRecursive(entity, videosByFolder, deletePaths);
        }
      }
    } catch (e) {}
  }
}
