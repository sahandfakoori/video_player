import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/data/model/subtitle_model.dart';
import 'package:flutter_application_1/data/model/video_model.dart';
import 'package:flutter_application_1/presentation/video_player_screen/widgets/edit_subtitle.dart';
import 'package:flutter_application_1/presentation/video_player_screen/widgets/brightness_volume.dart';
import 'package:flutter_application_1/presentation/video_player_screen/widgets/favorites_manager.dart';
import 'package:flutter_application_1/presentation/video_player_screen/widgets/logopositined.dart';
import 'package:flutter_application_1/presentation/video_player_screen/widgets/mute.dart';
import 'package:flutter_application_1/presentation/video_player_screen/widgets/rotate.dart';
import 'package:flutter_application_1/presentation/video_player_screen/widgets/speed.dart';
import 'package:flutter_application_1/presentation/video_player_screen/widgets/trimmer_view.dart';
import 'package:flutter_application_1/widgets/icon_button_widget.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as path;
import 'package:volume_controller/volume_controller.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;
  final List<VideoModel> videos;
  final int initialIndex;
  final bool isInFavoritesScreen;

  const VideoPlayerScreen({
    super.key,
    required this.video,
    required this.videos,
    required this.initialIndex,
    this.isInFavoritesScreen = false,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  late MuteController mutecontroller;
  bool _showControls = false;
  Timer? _hideTimer;
  late int currentIndex;
  double _currentVolume = 0.5;
  BoxFit _currentFit = BoxFit.contain;
  bool isLock = false;
  bool touch = false;
  final _controller = ScreenshotController();
  double _subtitleFontSize = 18.0;
  Color _subtitleFontColor = Colors.white;
  Color _subtitleBgColor = Colors.black54;
  bool isSpeedChanged = false;
  bool isSubtitleOn = false;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _loadVideo(currentIndex);
    VolumeController.instance.showSystemUI = false;
    VolumeController.instance.getVolume().then((value) {
      setState(() => _currentVolume = value);
    });
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _hideTimer?.cancel();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _captureScreen() async {
    final image = await _controller.capture();
    if (image == null) return;
    await saveScreenshot(image);
  }

  Future<String> saveScreenshot(Uint8List bytes) async {
    await [Permission.storage].request();
    final time = DateTime.now();
    final name = 'Screenshot_$time';
    final resualt = await ImageGallerySaverPlus.saveImage(bytes, name: name);
    if (resualt != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Screenshot saved at: /Internal Storage/Pictures',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to save screenshot',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
    return resualt['filePath'];
  }

  Future<List<SubtitleModel>> parseSrtFile(String filePath) async {
    final fileContent = await File(filePath).readAsString();
    final regex = RegExp(
      r'(\d+)\s+(\d{2}:\d{2}:\d{2}[,\.]\d{3}) --> (\d{2}:\d{2}:\d{2}[,\.]\d{3})\s+([\s\S]*?)(?=\r?\n\r?\n|\Z)',
      multiLine: true,
    );

    List<SubtitleModel> subtitles = [];

    for (final match in regex.allMatches(fileContent)) {
      final start = _parseDuration(match.group(2)!);
      final end = _parseDuration(match.group(3)!);
      final text = match.group(4)!.trim().replaceAll('\n', ' ');

      subtitles.add(SubtitleModel(start: start, end: end, text: text));
    }

    return subtitles;
  }

  Duration _parseDuration(String timeString) {
    final parts = timeString.split(RegExp('[:,]'));
    return Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
      seconds: int.parse(parts[2]),
      milliseconds: int.parse(parts[3]),
    );
  }

  List<SubtitleModel> _subtitles = [];

  Future<void> _pickSubtitle() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['srt'],
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final parsed = await parseSrtFile(path);
      setState(() {
        _subtitles = parsed;
        print("Loaded ${_subtitles.length} subtitles");
      });
    }
  }

  Future<void> _loadVideo(int index) async {
    if (index < 0 || index >= widget.videos.length) return;

    await _videoPlayerController?.dispose();
    currentIndex = index;

    final videoPath = widget.videos[currentIndex].path;

    if (videoPath.startsWith('http')) {
      try {
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(videoPath),
        );
      } catch (e) {
        _videoPlayerController = VideoPlayerController.network(videoPath);
      }
    } else {
      _videoPlayerController = VideoPlayerController.file(
        widget.videos[currentIndex].file,
      );
    }

    try {
      await _videoPlayerController!.initialize();

      mutecontroller = MuteController(
        videoPlayerController: _videoPlayerController!,
      );
      await _videoPlayerController!.play();
      _videoPlayerController!.setLooping(true);
      _videoPlayerController!.addListener(() {
        if (mounted) setState(() {});
      });
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('error in loadin video... $e')));
      }
    }
  }

  void _toggleFavorite() async {
    final file = widget.videos[currentIndex];
    await FavoritesManager().toggleFavorites(file);

    if (widget.isInFavoritesScreen &&
        !FavoritesManager().isFavorite(file.path)) {
      if (!mounted) return;

      if (currentIndex >= 0 && currentIndex < widget.videos.length) {
        widget.videos.removeAt(currentIndex);
      }

      if (widget.videos.isEmpty) {
        if (mounted) Navigator.pop(context);
        return;
      }

      if (currentIndex >= widget.videos.length) {
        currentIndex = widget.videos.length - 1;
      }

      await _loadVideo(currentIndex);
      return;
    }

    setState(() {});
  }

  void _playNextVideo() async {
    int nextIndex = currentIndex < widget.videos.length - 1
        ? currentIndex + 1
        : 0;
    await _loadVideo(nextIndex);
  }

  void _playPreviousVideo() async {
    if (currentIndex > 0) await _loadVideo(currentIndex - 1);
  }

  void _playOrStop() {
    if (_videoPlayerController == null ||
        !_videoPlayerController!.value.isInitialized)
      return;

    setState(() {
      if (_videoPlayerController!.value.isPlaying) {
        _videoPlayerController!.pause();
      } else {
        _videoPlayerController!.play();
      }
      _showControls = true;
    });

    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 7), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes : $seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            BrightnessVolumeOverlay(
              child: Center(
                child:
                    (_videoPlayerController != null &&
                        _videoPlayerController!.value.isInitialized)
                    ? SizedBox.expand(
                        child: FittedBox(
                          key: ValueKey(_currentFit),
                          fit: _currentFit,
                          child: Screenshot(
                            controller: _controller,
                            child: SizedBox(
                              width: _videoPlayerController!.value.size.width,
                              height: _videoPlayerController!.value.size.height,
                              child: VideoPlayer(_videoPlayerController!),
                            ),
                          ),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),

            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() => _showControls = !_showControls);
                  _hideTimer?.cancel();
                  _hideTimer = Timer(const Duration(seconds: 3), () {
                    if (mounted) setState(() => _showControls = false);
                  });
                },
              ),
            ),

            if (isLock)
              Positioned(
                top: 20,
                right: 20,
                child: IconButtonWidget(
                  icon: Icons.lock,
                  onPressed: () {
                    setState(() {
                      isLock = false;
                      _showControls = true;
                      _hideTimer?.cancel();
                      _hideTimer = Timer(const Duration(seconds: 3), () {
                        if (mounted) setState(() => _showControls = false);
                      });
                    });
                  },
                ),
              ),

            if (_subtitles.isNotEmpty &&
                _videoPlayerController != null &&
                _videoPlayerController!.value.isInitialized)
              Positioned(
                bottom: 40,
                left: 10,
                right: 10,
                child: Center(
                  child: Builder(
                    builder: (context) {
                      final position = _videoPlayerController!.value.position;
                      final current = _subtitles.firstWhere(
                        (sub) => position >= sub.start && position <= sub.end,
                        orElse: () => SubtitleModel(
                          start: Duration.zero,
                          end: Duration.zero,
                          text: "",
                        ),
                      );
                      return Text(
                        current.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _subtitleFontColor,

                          fontSize: _subtitleFontSize,
                          fontWeight: FontWeight.bold,
                          backgroundColor: _subtitleBgColor,
                        ),
                      );
                    },
                  ),
                ),
              ),

            if (_showControls && isLock == false)
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.75,
                              child: Text(
                                widget.videos.isNotEmpty
                                    ? path.basename(
                                        widget.videos[currentIndex].path,
                                      )
                                    : "no video",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              widget.videos.isNotEmpty
                                  ? '${currentIndex + 1} / ${widget.videos.length}'
                                  : '0 / 0',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: isSpeedChanged
                                    ? Colors.blue
                                    : Colors.grey[800],
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Center(
                                child: IconButtonWidget(
                                  icon: Icons.speed,
                                  onPressed: () {
                                    showSpeedOptions(
                                      context,
                                      _videoPlayerController!,
                                      (hasChaned) => setState(() {
                                        isSpeedChanged = hasChaned;
                                      }),
                                    );
                                  },
                                ),
                              ),
                            ),

                            Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color:
                                    FavoritesManager().isFavorite(
                                      widget.videos[currentIndex].path,
                                    )
                                    ? Colors.blue
                                    : Colors.grey[800],
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Center(
                                child: IconButtonWidget(
                                  icon:
                                      FavoritesManager().isFavorite(
                                        widget.videos[currentIndex].path,
                                      )
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color:
                                      FavoritesManager().isFavorite(
                                        widget.videos[currentIndex].path,
                                      )
                                      ? Colors.red
                                      : Colors.white,
                                  onPressed: () {
                                    _toggleFavorite();
                                  },
                                ),
                              ),
                            ),

                            Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: mutecontroller.isMuted
                                    ? Colors.blue
                                    : Colors.grey[800],
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Center(
                                child: IconButtonWidget(
                                  icon: mutecontroller.isMuted
                                      ? Icons.volume_off
                                      : Icons.volume_up,
                                  color: Colors.white,
                                  onPressed: () => setState(
                                    () => mutecontroller.toggleMute(),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Center(
                                child: IconButtonWidget(
                                  icon: Icons.screenshot_outlined,
                                  onPressed: () {
                                    _captureScreen();
                                  },
                                ),
                              ),
                            ),
                            Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: isSubtitleOn
                                    ? Colors.blue
                                    : Colors.grey[800],
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Center(
                                child: IconButtonWidget(
                                  icon: Icons.closed_caption,
                                  color: Colors.white,
                                  onPressed: () async {
                                    if (_subtitles.isNotEmpty) {
                                      setState(() {
                                        _subtitles.clear();
                                        isSubtitleOn = false;
                                      });
                                    } else {
                                      await _pickSubtitle();
                                    }
                                  },
                                ),
                              ),
                            ),

                            Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Center(
                                child: PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                  onSelected: (value) async {
                                    if (value == 'edit_video') {
                                      final file =
                                          widget.videos[currentIndex].file;
                                      _videoPlayerController!.pause();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              TrimmerView(file),
                                        ),
                                      );
                                    } else if (value == 'edit_subtitle') {
                                      final result =
                                          await Navigator.push<
                                            Map<String, dynamic>?
                                          >(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EditSubtitle(
                                                    initialFontSize:
                                                        _subtitleFontSize,
                                                    initialFontColorValue:
                                                        _subtitleFontColor
                                                            .value,
                                                    initialBgColorValue:
                                                        _subtitleBgColor.value,
                                                  ),
                                            ),
                                          );

                                      if (result != null) {
                                        setState(() {
                                          _subtitleFontSize =
                                              (result['fontSize'] as double?) ??
                                              _subtitleFontSize;
                                          _subtitleFontColor = Color(
                                            result["fontColor"] as int? ??
                                                _subtitleFontColor.value,
                                          );
                                          _subtitleBgColor = Color(
                                            result['bgColor'] as int? ??
                                                _subtitleBgColor.value,
                                          );
                                        });
                                      }
                                    }
                                  },
                                  itemBuilder: (BuildContext context) =>
                                      <PopupMenuEntry<String>>[
                                        const PopupMenuItem<String>(
                                          value: 'edit_video',
                                          child: Text('Edit Video'),
                                        ),
                                        const PopupMenuItem<String>(
                                          value: 'edit_subtitle',
                                          child: Text('Edit Subtitle'),
                                        ),
                                      ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(
                    height: 60,
                    width: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          left: 0,
                          child: IconButtonWidget(
                            icon: Icons.replay_10,
                            size: 40,
                            onPressed: () {
                              if (_videoPlayerController != null &&
                                  _videoPlayerController!.value.isInitialized) {
                                final position =
                                    _videoPlayerController!.value.position;
                                final newPos =
                                    position - const Duration(seconds: 10);
                                _videoPlayerController!.seekTo(
                                  newPos >= Duration.zero
                                      ? newPos
                                      : Duration.zero,
                                );
                              }
                            },
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: IconButtonWidget(
                            icon: Icons.forward_10,
                            size: 40,
                            onPressed: () {
                              if (_videoPlayerController != null &&
                                  _videoPlayerController!.value.isInitialized) {
                                final position =
                                    _videoPlayerController!.value.position;
                                final duration =
                                    _videoPlayerController!.value.duration;
                                final newPos =
                                    position + const Duration(seconds: 10);
                                _videoPlayerController!.seekTo(
                                  newPos <= duration ? newPos : duration,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              (_videoPlayerController != null &&
                                      _videoPlayerController!
                                          .value
                                          .isInitialized)
                                  ? _formatDuration(
                                      _videoPlayerController!.value.position,
                                    )
                                  : "00:00",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child:
                                  (_videoPlayerController != null &&
                                      _videoPlayerController!
                                          .value
                                          .isInitialized)
                                  ? SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 6,
                                        ),
                                        trackHeight: 2,
                                        activeTrackColor: Colors.blue,
                                        inactiveTrackColor: Colors.grey,
                                        thumbColor: Colors.white,
                                        overlayColor: Colors.white24,
                                      ),
                                      child: Slider(
                                        value: _videoPlayerController!
                                            .value
                                            .position
                                            .inMilliseconds
                                            .toDouble(),
                                        min: 0,
                                        max: _videoPlayerController!
                                            .value
                                            .duration
                                            .inMilliseconds
                                            .toDouble(),
                                        onChanged: (value) =>
                                            _videoPlayerController!.seekTo(
                                              Duration(
                                                milliseconds: value.toInt(),
                                              ),
                                            ),
                                      ),
                                    )
                                  : const SizedBox(),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              (_videoPlayerController != null &&
                                      _videoPlayerController!
                                          .value
                                          .isInitialized)
                                  ? _formatDuration(
                                      _videoPlayerController!.value.duration,
                                    )
                                  : "00:00",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButtonWidget(
                              icon: isLock ? Icons.lock : Icons.lock_open,
                              onPressed: () {
                                setState(() {
                                  isLock = !isLock;
                                  print(isLock);
                                });
                              },
                            ),
                            IconButtonWidget(
                              icon: Icons.skip_previous,
                              onPressed: () {
                                _playPreviousVideo();
                              },
                              size: 50,
                            ),
                            IconButtonWidget(
                              icon:
                                  (_videoPlayerController != null &&
                                      _videoPlayerController!
                                          .value
                                          .isInitialized &&
                                      _videoPlayerController!.value.isPlaying)
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              onPressed: () {
                                _playOrStop();
                              },
                              size: 50,
                            ),
                            IconButtonWidget(
                              icon: Icons.skip_next,
                              onPressed: () {
                                _playNextVideo();
                              },
                              size: 50,
                            ),
                            IconButtonWidget(
                              icon: Icons.screen_rotation,
                              size: 20,
                              onPressed: () {
                                RotateHelper.toggleRotation();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            DraggableLogo(
              imagePath: 'assets/images/logo.png',
              initialX: 20,
              initialY: 20,
              width: 60,
              height: 60,
            ),
          ],
        ),
      ),
    );
  }
}
