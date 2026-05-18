import 'dart:io';
import 'package:flutter_application_1/data/model/video_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesManager {
  static final FavoritesManager _instance = FavoritesManager._internal();
  factory FavoritesManager() => _instance;
  FavoritesManager._internal();

  final List<VideoModel> _favorites = [];
  List<VideoModel> get favorites => _favorites;

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final paths = prefs.getStringList('favorites_videos') ?? [];

    _favorites.clear();
    for (var path in paths) {
      final file = File(path);
      final name = path.split(Platform.pathSeparator).last;
      if (await file.exists()) {
        _favorites.add(
          VideoModel(path: path, name: name, file: file, isFavorite: true),
        );
      }
    }
  }

  Future<void> saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final paths = _favorites.map((v) => v.path).toList();
    await prefs.setStringList('favorites_videos', paths);
  }

  Future<void> toggleFavorites(VideoModel video) async {
    final exists = _favorites.any((v) => v.path == video.path);
    if (exists) {
      _favorites.removeWhere((v) => v.path == video.path);
      video.isFavorite = false;
    } else {
      video.isFavorite = true;
      _favorites.add(video);
    }
    await saveFavorites();
  }

  bool isFavorite(String path) {
    return _favorites.any((v) => v.path == path);
  }
}
