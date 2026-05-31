import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../database/data_repository.dart';
import '../utils/theme.dart';
import 'tag_manage_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const SizedBox(height: 20),

          _SectionHeader(title: '自动记账'),
          _SectionCard(children: [
            Consumer<SettingsProvider>(
              builder: (context, settings, _) {
                return _SwitchTile(
                  icon: Icons.notifications_active,
                  iconColor: AppTheme.warningOrange,
                  title: '通知自动记账',
                  subtitle: '读取支付通知自动记录账目',
                  value: settings.autoRecordEnabled,
                  onChanged: (v) => settings.setAutoRecordEnabled(v),
                );
              },
            ),
          ]),

          const SizedBox(height: 20),

          _SectionHeader(title: '外观'),
          _SectionCard(children: [
            Consumer<SettingsProvider>(
              builder: (context, settings, _) {
                return _SwitchTile(
                  icon: Icons.dark_mode,
                  iconColor: AppTheme.primaryBlue,
                  title: '深色模式',
                  subtitle: '切换深色/浅色主题',
                  value: settings.darkModeEnabled,
                  onChanged: (v) => settings.setDarkModeEnabled(v),
                );
              },
            ),
          ]),

          const SizedBox(height: 20),

          _SectionHeader(title: '数据管理'),
          _SectionCard(children: [
            _ActionTile(
              icon: Icons.download,
              iconColor: AppTheme.primaryBlue,
              title: '导出数据',
              subtitle: '导出全部数据为 JSON 文件',
              onTap: () => _exportData(context),
            ),
            _Divider(context),
            _ActionTile(
              icon: Icons.upload_file,
              iconColor: AppTheme.warningOrange,
              title: '导入数据',
              subtitle: '从 JSON 文件导入（会覆盖现有数据）',
              onTap: () => _importData(context),
            ),
            _Divider(context),
            _ActionTile(
              icon: Icons.restore,
              iconColor: AppTheme.successGreen,
              title: '恢复备份',
              subtitle: '从自动备份中恢复数据',
              onTap: () => _restoreBackup(context),
            ),
          ]),

          const SizedBox(height: 20),

          _SectionHeader(title: '标签'),
          _SectionCard(children: [
            _ActionTile(
              icon: Icons.label,
              iconColor: AppTheme.primaryBlue,
              title: '管理标签',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TagManageScreen()));
              },
            ),
          ]),

          const SizedBox(height: 20),

          _SectionHeader(title: '关于'),
          _SectionCard(children: [
            _ActionTile(
              icon: Icons.info_outline,
              iconColor: AppTheme.text2(context),
              title: 'Lokii 记账',
              subtitle: 'v1.0.0',
              showArrow: false,
              onTap: () {},
            ),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── 导出数据 ──────────────────────────────────────────────────────

  Future<void> _exportData(BuildContext context) async {
    final dir = await FilePicker.platform.getDirectoryPath(dialogTitle: '选择导出目录');
    if (dir == null) return;

    try {
      final path = await DataRepository.instance.exportToJson(directory: dir);
      if (context.mounted) _showResult(context, '导出成功', '文件已保存到：\n$path');
    } catch (e) {
      if (context.mounted) _snack(context, '导出失败: $e');
    }
  }

  // ── 导入数据 ──────────────────────────────────────────────────────

  Future<void> _importData(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: '选择要导入的 JSON 文件',
    );
    if (result == null || result.files.isEmpty) return;
    final filePath = result.files.single.path;
    if (filePath == null) return;

    // 确认覆盖
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认导入'),
        content: const Text('导入会覆盖现有所有数据，系统会先自动备份。\n\n确定继续吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定导入', style: TextStyle(color: AppTheme.warningOrange)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final importResult = await DataRepository.instance.importFromJson(filePath);
      if (context.mounted) {
        // 刷新数据
        context.read<TransactionProvider>().refreshAfterImport();
        context.read<SettingsProvider>().loadSettings();

        final backupMsg = importResult.backupPath != null
            ? '\n\n已自动备份到：\n${importResult.backupPath}'
            : '';
        _showResult(context, '导入成功', '导入完成：${importResult.summary}$backupMsg');
      }
    } catch (e) {
      if (context.mounted) _snack(context, '导入失败: $e');
    }
  }

  // ── 恢复备份 ──────────────────────────────────────────────────────

  Future<void> _restoreBackup(BuildContext context) async {
    // 也可以选择外部文件
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('恢复备份'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'auto'),
            child: const ListTile(
              leading: Icon(Icons.history),
              title: Text('从自动备份恢复'),
              subtitle: Text('选择最近的自动备份'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'file'),
            child: const ListTile(
              leading: Icon(Icons.file_open),
              title: Text('从文件恢复'),
              subtitle: Text('选择外部 JSON 备份文件'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
    if (choice == null) return;

    String? filePath;

    if (choice == 'auto') {
      final backups = await DataRepository.instance.getBackups();
      if (backups.isEmpty) {
        if (context.mounted) _snack(context, '没有找到自动备份');
        return;
      }

      // 显示备份列表
      if (context.mounted) {
        filePath = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          builder: (ctx) => _BackupListSheet(backups: backups),
        );
      }
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: '选择备份文件',
      );
      filePath = result?.files.single.path;
    }

    if (filePath == null) return;

    // 确认恢复
    if (context.mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('确认恢复'),
          content: const Text('恢复会覆盖现有所有数据，确定继续吗？'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确定恢复', style: TextStyle(color: AppTheme.successGreen)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    try {
      final importResult = await DataRepository.instance.restoreFromBackup(filePath);
      if (context.mounted) {
        context.read<TransactionProvider>().refreshAfterImport();
        context.read<SettingsProvider>().loadSettings();
        _showResult(context, '恢复成功', '已恢复：${importResult.summary}');
      }
    } catch (e) {
      if (context.mounted) _snack(context, '恢复失败: $e');
    }
  }

  // ── 辅助方法 ──────────────────────────────────────────────────────

  void _showResult(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SelectableText(content),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('确定'))],
      ),
    );
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ── 备份列表底部弹窗 ────────────────────────────────────────────────

class _BackupListSheet extends StatelessWidget {
  final List<dynamic> backups; // List<File>

  const _BackupListSheet({required this.backups});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 36, height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.separator(ctx).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('选择备份', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.text1(ctx))),
              ),
              const Divider(height: 0.5),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: backups.length,
                  itemBuilder: (_, index) {
                    final file = backups[index];
                    final name = file.path.split(RegExp(r'[/\\]')).last;
                    final modTime = file.lastModifiedSync();
                    final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(modTime);

                    return ListTile(
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.backup, color: AppTheme.primaryBlue, size: 18),
                      ),
                      title: Text(timeStr, style: TextStyle(color: AppTheme.text1(ctx))),
                      subtitle: Text(name, style: TextStyle(fontSize: 12, color: AppTheme.text2(ctx))),
                      onTap: () => Navigator.pop(ctx, file.path),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── 构建块 ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 16, 8),
      child: Text(title.toUpperCase(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppTheme.text2(context))),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: AppTheme.cardColor(context), borderRadius: BorderRadius.circular(12)),
      child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(12), child: Column(children: children)),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool showArrow;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.showArrow = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(title, style: TextStyle(color: AppTheme.text1(context))),
      subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(color: AppTheme.text2(context), fontSize: 12)) : null,
      trailing: showArrow ? Icon(Icons.chevron_right, color: AppTheme.text3(context), size: 20) : null,
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(title, style: TextStyle(color: AppTheme.text1(context))),
      subtitle: Text(subtitle, style: TextStyle(color: AppTheme.text2(context), fontSize: 12)),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: AppTheme.primaryBlue),
    );
  }
}

Widget _Divider(BuildContext context) {
  return Divider(height: 0.5, indent: 56, color: AppTheme.separator(context));
}
