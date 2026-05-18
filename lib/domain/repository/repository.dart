import 'dart:io';

abstract class Repository {
  Future<void> scanDirectoryRecursive(Directory dir,
   Map<String, List<File>> videosByFolder,
   List<String> deletePaths,);
}