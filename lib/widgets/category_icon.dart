import 'package:flutter/material.dart';

class CategoryIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool isSelected;

  const CategoryIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 48,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.2) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(size * 0.25),
        border: isSelected ? Border.all(color: color, width: 2) : null,
      ),
      child: Icon(icon, color: isSelected ? color : const Color(0xFF8E8E93), size: size * 0.5),
    );
  }
}
