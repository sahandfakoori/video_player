import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:video_trimmer/video_trimmer.dart';

class TrimmerView extends StatefulWidget {
  final File file;

  const TrimmerView(this.file, {super.key});

  @override
  _TrimmerViewState createState() => _TrimmerViewState();
}

class _TrimmerViewState extends State<TrimmerView> {
  final Trimmer _trimmer = Trimmer();

  double _startValue = 0.0;
  double _endValue = 0.0;

  bool _isPlaying = false;
  bool _progressVisibility = false;

  Future<void> _saveVideo() async {
    setState(() {
      _progressVisibility = true;
    });

    await _trimmer.saveTrimmedVideo(
      startValue: _startValue,
      endValue: _endValue,
      onSave: (String? outputPath) async {
        setState(() {
          _progressVisibility = false;
        });

        if (outputPath != null) {
          final File trimmedFile = File(outputPath);

          final result = await ImageGallerySaverPlus.saveFile(trimmedFile.path);

          if (result != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Video successfully saved to gallery."),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to save video.")),
            );
          }

          Navigator.pop(context, trimmedFile.path);
        }
      },
    );
  }

  void _loadVideo() {
    _trimmer.loadVideo(videoFile: widget.file);
  }

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Video Trimmer")),
      body: Center(
        child: Container(
          padding: const EdgeInsets.only(bottom: 30.0),
          color: Colors.black,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_progressVisibility)
                const LinearProgressIndicator(backgroundColor: Colors.red),

              Expanded(child: VideoViewer(trimmer: _trimmer)),

              TrimViewer(
                trimmer: _trimmer,
                viewerHeight: 50.0,
                viewerWidth: MediaQuery.of(context).size.width,

                onChangeStart: (value) => _startValue = value,
                onChangeEnd: (value) => _endValue = value,
                onChangePlaybackState: (value) =>
                    setState(() => _isPlaying = value),
              ),

              TextButton(
                child: _isPlaying
                    ? const Icon(Icons.pause, size: 80.0, color: Colors.white)
                    : const Icon(
                        Icons.play_arrow,
                        size: 80.0,
                        color: Colors.white,
                      ),
                onPressed: () async {
                  final playbackState = await _trimmer.videoPlaybackControl(
                    startValue: _startValue,
                    endValue: _endValue,
                  );
                  setState(() {
                    _isPlaying = playbackState;
                  });
                },
              ),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                ),
                onPressed: _progressVisibility ? null : _saveVideo,
                child: const Text(
                  "Save Video",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
