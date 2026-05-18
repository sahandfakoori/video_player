import 'package:flutter/material.dart';

class IconButtonWidget extends StatelessWidget {
  final Function() onPressed;
  final IconData icon;
  final Color color;
  final double size;
  const IconButtonWidget({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = Colors.white,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,

      icon: Icon(icon, color: color, size: size),
    );
  }
}
