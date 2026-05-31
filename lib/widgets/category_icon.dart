import 'package:flutter/material.dart';
import '../utils/theme.dart';

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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.2) : AppTheme.card2Color(context),
        borderRadius: BorderRadius.circular(size * 0.25),
        border: isSelected ? Border.all(color: color, width: 2) : null,
      ),
      child: Icon(icon, color: isSelected ? color : AppTheme.text2(context), size: size * 0.5),
    );
  }
}
