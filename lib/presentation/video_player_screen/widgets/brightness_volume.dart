import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';

class BrightnessVolumeOverlay extends StatefulWidget {
  final Widget child;
  const BrightnessVolumeOverlay({super.key, required this.child});

  @override
  State<BrightnessVolumeOverlay> createState() =>
      _BrightnessVolumeOverlayState();
}

class _BrightnessVolumeOverlayState extends State<BrightnessVolumeOverlay> {
  double _brightness = 0.5;
  double _volume = 0.5;

  bool _isVerticalGesture = false;
  bool _isLeftSideGesture = false;
  Offset? _initialSwipeOffset;

  @override
  void initState() {
    super.initState();
    _initValues();
    VolumeController.instance.showSystemUI = false;
  }

  Future<void> _initValues() async {
    _brightness = await ScreenBrightness().current;
    _volume = 0.5;
    setState(() {});
  }

  void _updateBrightness(double deltaY) async {
    setState(() {
      _brightness -= deltaY / 300;
      _brightness = _brightness.clamp(0.0, 1.0);
    });
    await ScreenBrightness().setScreenBrightness(_brightness);
  }

  void _updateVolume(double deltaY) async {
    setState(() {
      _volume -= deltaY / 300;
      _volume = _volume.clamp(0.0, 1.0);
    });
    await VolumeController.instance.setVolume(_volume);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        _initialSwipeOffset = details.localPosition;
        _isLeftSideGesture =
            _initialSwipeOffset!.dx < MediaQuery.of(context).size.width / 2;
      },
      onPanUpdate: (details) {
        if (details.delta.dy.abs() > details.delta.dx.abs()) {
          _isVerticalGesture = true;
        }
        if (_isVerticalGesture) {
          if (_isLeftSideGesture) {
            _updateBrightness(details.delta.dy);
          } else {
            _updateVolume(details.delta.dy);
          }
        }
      },
      onPanEnd: (_) {
        _isVerticalGesture = false;
      },
      child: Stack(
        children: [
          widget.child,

          if (_isLeftSideGesture && _isVerticalGesture)
            Positioned(
              left: 30,
              top: MediaQuery.of(context).size.height / 3,
              child: _buildIndicator(_brightness, Icons.brightness_6_rounded),
            ),

          if (!_isLeftSideGesture && _isVerticalGesture)
            Positioned(
              right: 30,
              top: MediaQuery.of(context).size.height / 3,
              child: _buildIndicator(_volume, Icons.volume_up_rounded),
            ),
        ],
      ),
    );
  }

  Widget _buildIndicator(double value, IconData icon) {
    return Container(
      height: 170,
      width: 40,
      decoration: BoxDecoration(
        color: Colors.grey[600],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: 40,
            height: 170 * value,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          Positioned(
            bottom: 5,
            child: Icon(icon, color: Colors.black, size: 28),
          ),
        ],
      ),
    );
  }
}
