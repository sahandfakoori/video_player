import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void removeVideoFromList({
  required BuildContext context,
  required File video,
  required List<File> videoList,
  required VoidCallback onRemoved,
}) async {
  videoList.remove(video);
  onRemoved();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('deleted video', style: TextStyle(fontSize: 16)),
      duration: Duration(seconds: 1),
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    ),
  );
}

Future<void> addToDeletedVideos(String path) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> deleteVideos = prefs.getStringList('delete Videos') ?? [];
  if (!deleteVideos.contains(path)) {
    deleteVideos.add(path);
    await prefs.setStringList('delete Videos', deleteVideos);
  }
}

Future<List<String>> getDeleteVideos() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getStringList('delete Videos') ?? [];
}
