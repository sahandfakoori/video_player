import 'dart:io';

class VideoModel {
  final String path;
  final String name;
  final File file;
  bool isFavorite;

  VideoModel({
    required this.path,
    required this.name,
    required this.file,
    this.isFavorite = false,
  });

  VideoModel copyWith({
    String? name,
    String? path,
    File? file,
    bool? isFavorite,
  }) {
    return VideoModel(
      name: name ?? this.name,
      path: path ?? this.path,
      file: file ?? this.file,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
