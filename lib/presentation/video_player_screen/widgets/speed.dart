import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void showSpeedOptions(
  BuildContext context,
  VideoPlayerController controller,
  Function(bool hasChaned) hasChanged,
) {
  double currentSpeed = controller.value.playbackSpeed;
  final List<double> commonSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 3.0];
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.black.withOpacity(0.6),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    isScrollControlled: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          void setSpeed(double speed) {
            setModalState(() {
              currentSpeed = speed;
            });
            controller.setPlaybackSpeed(speed);
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'playback Speed',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: commonSpeeds.map((speed) {
                      bool isSelected = (currentSpeed - speed).abs() < 0.01;
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected
                              ? Colors.blueAccent
                              : Colors.grey[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                        ),
                        onPressed: () => setSpeed(speed),
                        child: Text(
                          '${speed}x',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[300],
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${currentSpeed.toStringAsFixed(2)}x',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbColor: Colors.white,
                      activeTrackColor: Colors.blue,
                      inactiveTrackColor: Colors.white24,
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: currentSpeed,
                      min: 0.25,
                      max: 3.0,
                      divisions: 200,
                      label: '${currentSpeed.toStringAsFixed(2)}x',
                      onChanged: (value) {
                        setModalState(() {
                          currentSpeed = value;
                        });
                        controller.setPlaybackSpeed(value);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      hasChanged(
                        commonSpeeds.contains(currentSpeed) &&
                            currentSpeed != 1.0,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                    ),
                    child: const Text(
                      'Ok',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
