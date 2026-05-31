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
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        backgroundColor: isSelected ? AppTheme.primaryBlue : const Color(0xFFF2F2F7),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onDelete,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: const Color(0xFFE5E5EA)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
