import 'package:flutter/material.dart';

class DraggableLogo extends StatefulWidget {
  final String imagePath;
  final double initialX;
  final double initialY;
  final double width;
  final double height;

  const DraggableLogo({
    super.key,
    required this.imagePath,
    this.initialX = 0.1,
    this.initialY = 0.1,
    this.width = 80,
    this.height = 80,
  });

  @override
  State<DraggableLogo> createState() => _DraggableLogoState();
}

class _DraggableLogoState extends State<DraggableLogo> {
  late double _xPosition;
  late double _yPosition;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _xPosition = widget.initialX;
    _yPosition = widget.initialY;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _xPosition,
      top: _yPosition,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          setState(() {
            _isDragging = true;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _xPosition += details.delta.dx;
            _yPosition += details.delta.dy;

            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;

            _xPosition = _xPosition.clamp(0.0, screenWidth - widget.width);
            _yPosition = _yPosition.clamp(0.0, screenHeight - widget.height);
          });
        },
        onPanEnd: (details) {
          setState(() {
            _isDragging = false;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(widget.imagePath),
              fit: BoxFit.contain,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isDragging ? 0.5 : 0.3),
                blurRadius: _isDragging ? 10 : 5,
                spreadRadius: _isDragging ? 2 : 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
