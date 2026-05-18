import 'dart:io';

abstract class DataSource {
  Future<void> scanDirectoryRecursive(Directory dir,
   Map<String, List<File>> videosByFolder,
   List<String> deletePaths,);
}

