import 'package:video_player/video_player.dart';

class MuteController {
  final VideoPlayerController videoPlayerController;
  MuteController({required this.videoPlayerController});
  bool get isMuted => videoPlayerController.value.volume == 0;
  void toggleMute() {
    if (isMuted) {
      videoPlayerController.setVolume(3.0);
    } else {
      videoPlayerController.setVolume(0.0);
    }
  }
}
