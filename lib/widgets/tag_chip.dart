import 'package:flutter/material.dart';
import '../utils/theme.dart';

class TagChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TagChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (onDelete != null) {
      return Chip(
        label: Text(
          label,
          style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : AppTheme.text1(context)),
        ),
        backgroundColor: isSelected ? AppTheme.primaryBlue : AppTheme.card2Color(context),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onDelete,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : AppTheme.card2Color(context),
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: AppTheme.separator(context)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.white : AppTheme.text1(context),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
