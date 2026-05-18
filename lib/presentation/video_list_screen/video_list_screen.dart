import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/model/video_model.dart';
import 'package:flutter_application_1/presentation/video_player_screen/video_player_screen.dart';
import 'package:flutter_application_1/presentation/video_list_screen/widgets/delete.dart';
import 'package:flutter_application_1/presentation/video_list_screen/widgets/share.dart';
import 'package:flutter_application_1/widgets/icon_button_widget.dart';
import 'package:flutter_application_1/widgets/videoListTile.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class VideoListScreen extends StatefulWidget {
  final String folderName;
  final List<File> videos;

  const VideoListScreen({
    super.key,
    required this.folderName,
    required this.videos,
  });

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  List<VideoModel> videos = [];
  Map<File, Duration> videoDurations = {};

  @override
  void initState() {
    super.initState();
    _filterDeletedVideos();
    _loadVideoDurations();
  }

  Future<void> _filterDeletedVideos() async {
    final deletePaths = await getDeleteVideos();
    widget.videos.removeWhere((video) => deletePaths.contains(video.path));
  }

  Future<void> saveDurationToCache(String path, Duration duration) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(path, duration.inMilliseconds.toString());
  }

  Future<Duration?> loadDurationFromCache(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getString(path);
    if (ms != null) {
      return Duration(milliseconds: int.parse(ms));
    }
    return null;
  }

  Future<Duration> getCachedVideoDuration(File videoFile) async {
    final key = videoFile.path;

    final cached = await loadDurationFromCache(key);
    if (cached != null) return cached;

    try {
      if (!await videoFile.exists()) {
        print("File not found: ${videoFile.path}");
        return Duration.zero;
      }

      final controller = VideoPlayerController.file(videoFile);
      await controller.initialize();
      final duration = controller.value.duration;
      await controller.dispose();

      await saveDurationToCache(key, duration);
      return duration;
    } catch (e) {
      print(" error in getCachedVideoDuration: $e");
      return Duration.zero;
    }
  }

  Future<void> _loadVideoDurations() async {
    for (var video in widget.videos) {
      final duration = await getCachedVideoDuration(video);
      videoDurations[video] = duration;
    }
    setState(() {});
  }

  Future<String?> getCachedThumbnailPath(String videoPath) async {
    final cacheDir = await getTemporaryDirectory();

    final hashedName = sha1
        .convert(utf8.encode(videoPath))
        .toString(); //برای جلوگیری از تکرار میاد با هش کردن مسیرارو میسازه تا یکتا باشه
    final thumbPath = p.join(cacheDir.path, '$hashedName.jpg');

    final thumbFile = File(thumbPath);
    if (await thumbFile.exists() && await thumbFile.length() > 0) {
      return thumbPath;
    }

    final generatedPath = await VideoThumbnail.thumbnailFile(
      video: videoPath,
      thumbnailPath: thumbPath,
      imageFormat: ImageFormat.JPEG,
      maxHeight: 300,
      maxWidth: 300,
      quality: 100,
    );

    return generatedPath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,

        title: Text(
          widget.folderName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).appBarTheme.foregroundColor,
            fontWeight: FontWeight.w600,
            fontSize: 25,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Icon(Icons.arrow_back, size: 28),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: widget.videos.length,
        itemBuilder: (context, index) {
          final videoFile = widget.videos[index];
          final videoModel = VideoModel(
            path: videoFile.path,
            name: videoFile.path.split('/').last,
            file: videoFile,
            isFavorite: false,
          );

          return VideoListTile(
            video: videoModel,
            onTap: () {
              final videoModels = widget.videos.map((file) {
                return VideoModel(
                  path: file.path,
                  name: file.path.split('/').last,
                  file: file,
                  isFavorite: false,
                );
              }).toList();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(
                    video: videoModels[index],
                    videos: videoModels,
                    initialIndex: index,
                  ),
                ),
              );
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () async {
                    final confirm = await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        content: const Text(
                          'delete this item from videos?',
                          style: TextStyle(fontSize: 20, color: Colors.black),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(ctx).pop(true);
                              addToDeletedVideos(videoFile.path);
                              setState(() {});
                            },
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      final videoToDelete = widget.videos[index];
                      await addToDeletedVideos(videoToDelete.path);
                      removeVideoFromList(
                        context: context,
                        video: videoToDelete,
                        videoList: widget.videos,
                        onRemoved: () => setState(() {}),
                      );
                    }
                  },
                  icon: const Icon(Icons.delete),
                ),
                IconButtonWidget(
                  icon: Icons.share,
                  onPressed: () {
                    VideoShareHelper.shareVideo(videoFile);
                  },
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.black
                      : Colors.white,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
