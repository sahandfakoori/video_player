import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/model/video_model.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VideoListTile extends StatefulWidget {
  final VideoModel video;
  final VoidCallback? onTap;
  final Widget? trailing;

  const VideoListTile({
    super.key,
    required this.video,
    this.onTap,
    this.trailing,
  });

  @override
  State<VideoListTile> createState() => _VideoListTileState();
}

class _VideoListTileState extends State<VideoListTile> {
  Duration? duration;
  String? thumbPath;

  @override
  void initState() {
    super.initState();
    _loadVideoInfo();
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

    final controller = VideoPlayerController.file(videoFile);
    await controller.initialize();
    final duration = controller.value.duration;
    controller.dispose();

    await saveDurationToCache(key, duration);
    return duration;
  }

  Future<String?> getCachedThumbnailPath(String videoPath) async {
    final cacheDir = await getTemporaryDirectory();
    final hashedName = sha1.convert(utf8.encode(videoPath)).toString();
    final thumbPath = p.join(cacheDir.path, '$hashedName.jpg');

    final thumbFile = File(thumbPath);
    if (await thumbFile.exists() && await thumbFile.length() > 0) {
      return thumbPath;
    }

    return await VideoThumbnail.thumbnailFile(
      video: videoPath,
      thumbnailPath: thumbPath,
      imageFormat: ImageFormat.JPEG,
      maxHeight: 300,
      maxWidth: 300,
      quality: 100,
    );
  }

  Future<void> _loadVideoInfo() async {
    try {
      final d = await getCachedVideoDuration(widget.video.file);
      final t = await getCachedThumbnailPath(widget.video.file.path);

      if (!mounted) return;
      setState(() {
        duration = d;
        thumbPath = t;
      });
    } catch (e) {
      print("error on loading...: $e");
    }
  }

  String formatBytes(int bytes) {
    final mb = bytes / (1024 * 1024);
    if (mb < 1024) {
      return "${mb.toStringAsFixed(2)} MB";
    } else {
      final gb = mb / 1024;
      return "${gb.toStringAsFixed(2)} GB";
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizeInByte = widget.video.file.lengthSync();
    final fileSizeText = formatBytes(sizeInByte);

    final durationText = duration != null
        ? '${duration!.inMinutes}:${(duration!.inSeconds % 60).toString().padLeft(2, '0')}'
        : '...';

    return ListTile(
      leading: thumbPath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(thumbPath!),
                width: 80,
                height: 60,
                fit: BoxFit.cover,
              ),
            )
          : const SizedBox(
              width: 80,
              height: 60,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
      title: Text(
        widget.video.name.length > 11
            ? widget.video.name.substring(0, 11) + "..."
            : widget.video.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Row(
        children: [
          Text(
            durationText,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(width: 20),
          Text(
            fileSizeText,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
      onTap: widget.onTap,

      trailing: widget.trailing,
    );
  }
}
