import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/tag.dart';
import '../utils/theme.dart';

class TagManageScreen extends StatefulWidget {
  const TagManageScreen({super.key});

  @override
  State<TagManageScreen> createState() => _TagManageScreenState();
}

class _TagManageScreenState extends State<TagManageScreen> {
  List<Tag> _tags = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    final maps = await DBHelper.instance.getTags();
    setState(() {
      _tags = maps.map((m) => Tag.fromMap(m)).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: const Text('标签管理'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddDialog),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tags.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.label_off, size: 64, color: AppTheme.text3(context)),
                      const SizedBox(height: 16),
                      Text('还没有标签',
                          style: TextStyle(color: AppTheme.text2(context), fontSize: 17)),
                      const SizedBox(height: 8),
                      Text('记账时可以添加标签',
                          style: TextStyle(color: AppTheme.text3(context), fontSize: 15)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tags.length,
                  itemBuilder: (_, index) {
                    final tag = _tags[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.label, color: AppTheme.primaryBlue, size: 18),
                          ),
                          title: Text(tag.name,
                              style: TextStyle(color: AppTheme.text1(context))),
                          subtitle: Text('使用 ${tag.useCount} 次',
                              style: TextStyle(color: AppTheme.text2(context))),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppTheme.destructiveRed),
                            onPressed: () => _deleteTag(tag),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showAddDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加标签'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: '输入标签名称'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                await DBHelper.instance.insertTag({
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'name': name,
                  'useCount': 0,
                  'lastUsedAt': DateTime.now().toIso8601String(),
                });
                await _loadTags();
              }
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTag(Tag tag) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除标签"${tag.name}"吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: AppTheme.destructiveRed)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DBHelper.instance.deleteTag(tag.id);
      await _loadTags();
    }
  }
}
