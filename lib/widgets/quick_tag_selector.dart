import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/tag.dart';
import '../utils/theme.dart';

class QuickTagSelector extends StatefulWidget {
  final List<String> selectedTags;
  final ValueChanged<String> onTagToggle;

  const QuickTagSelector({
    super.key,
    required this.selectedTags,
    required this.onTagToggle,
  });

  @override
  State<QuickTagSelector> createState() => _QuickTagSelectorState();
}

class _QuickTagSelectorState extends State<QuickTagSelector> {
  List<Tag> _recentTags = [];
  final List<String> _presetTags = ['日常', '工作', '社交', '家庭', '个人', '旅行', '学习', '健康'];

  @override
  void initState() {
    super.initState();
    _loadRecentTags();
  }

  Future<void> _loadRecentTags() async {
    final maps = await DBHelper.instance.getTags(limit: 8);
    if (mounted) {
      setState(() => _recentTags = maps.map((m) => Tag.fromMap(m)).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 最近使用的标签
        if (_recentTags.isNotEmpty) ...[
          Text('最近使用', style: TextStyle(fontSize: 13, color: AppTheme.text3(context))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentTags.map((tag) {
              final selected = widget.selectedTags.contains(tag.name);
              return _TagChip(label: tag.name, isSelected: selected, onTap: () => widget.onTagToggle(tag.name));
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // 预设标签
        Text('常用标签', style: TextStyle(fontSize: 13, color: AppTheme.text3(context))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presetTags.map((tag) {
            final selected = widget.selectedTags.contains(tag);
            return _TagChip(label: tag, isSelected: selected, onTap: () => widget.onTagToggle(tag));
          }).toList(),
        ),

        // 已选标签
        if (widget.selectedTags.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('已选标签', style: TextStyle(fontSize: 13, color: AppTheme.text3(context))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selectedTags.map((tag) {
              return Chip(
                label: Text(tag, style: const TextStyle(fontSize: 13, color: Colors.white)),
                backgroundColor: AppTheme.primaryBlue,
                deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
                onDeleted: () => widget.onTagToggle(tag),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TagChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
