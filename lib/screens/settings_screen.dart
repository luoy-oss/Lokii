import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../database/export_helper.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
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
              title: '导出本月数据',
              subtitle: '保存 CSV 到本地',
              onTap: () => _exportCurrentMonth(context),
            ),
            _Divider(context),
            _ActionTile(
              icon: Icons.calendar_month,
              iconColor: AppTheme.successGreen,
              title: '导出指定月份',
              subtitle: '保存 CSV 到本地',
              onTap: () => _exportByMonth(context),
            ),
            _Divider(context),
            _ActionTile(
              icon: Icons.all_inclusive,
              iconColor: AppTheme.destructiveRed,
              title: '导出全部数据',
              subtitle: '保存 CSV 到本地',
              onTap: () => _exportAll(context),
            ),
            _Divider(context),
            _ActionTile(
              icon: Icons.upload_file,
              iconColor: AppTheme.warningOrange,
              title: '导入数据',
              subtitle: '从 CSV 文件导入',
              onTap: () => _importData(context),
            ),
          ]),

          const SizedBox(height: 20),

          _SectionHeader(title: '配置管理'),
          _SectionCard(children: [
            _ActionTile(
              icon: Icons.save,
              iconColor: AppTheme.primaryBlue,
              title: '导出配置',
              subtitle: '保存设置、标签、分类',
              onTap: () => _exportConfig(context),
            ),
            _Divider(context),
            _ActionTile(
              icon: Icons.restore,
              iconColor: AppTheme.successGreen,
              title: '导入配置',
              subtitle: '恢复设置、标签、分类',
              onTap: () => _importConfig(context),
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

  Future<void> _exportCurrentMonth(BuildContext context) async {
    final provider = context.read<TransactionProvider>();
    final now = DateTime.now();
    final txns = await provider.getAllTransactions(
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
    if (txns.isEmpty) return _snack(context, '本月没有数据可导出');
    final path = await ExportHelper.exportAndSave(txns, dateRange: Formatters.month(now));
    _showExportResult(context, path);
  }

  Future<void> _exportByMonth(BuildContext context) async {
    final provider = context.read<TransactionProvider>();
    final now = DateTime.now();
    final last = DateTime(now.year, now.month - 1);
    final txns = await provider.getAllTransactions(
      startDate: DateTime(last.year, last.month, 1),
      endDate: DateTime(last.year, last.month + 1, 0, 23, 59, 59),
    );
    if (txns.isEmpty) return _snack(context, '上月没有数据可导出');
    final path = await ExportHelper.exportAndSave(txns, dateRange: Formatters.month(last));
    _showExportResult(context, path);
  }

  Future<void> _exportAll(BuildContext context) async {
    final provider = context.read<TransactionProvider>();
    final txns = await provider.getAllTransactions();
    if (txns.isEmpty) return _snack(context, '没有数据可导出');
    final path = await ExportHelper.exportAndSave(txns, dateRange: '全部');
    _showExportResult(context, path);
  }

  // ── 导入数据 ──────────────────────────────────────────────────────

  Future<void> _importData(BuildContext context) async {
    // 显示输入路径对话框
    final path = await _showPathInputDialog(
      context,
      title: '导入数据',
      hint: '输入 CSV 文件路径',
    );
    if (path == null || path.isEmpty) return;

    try {
      final count = await ExportHelper.exportToCSV([], directory: path) as dynamic;
      // 实际导入逻辑
      _snack(context, '导入功能需要选择文件');
    } catch (e) {
      _snack(context, '导入失败: $e');
    }
  }

  // ── 导出/导入配置 ─────────────────────────────────────────────────

  Future<void> _exportConfig(BuildContext context) async {
    try {
      final path = await ExportHelper.exportConfig();
      _showExportResult(context, path.path);
    } catch (e) {
      _snack(context, '导出配置失败: $e');
    }
  }

  Future<void> _importConfig(BuildContext context) async {
    final path = await _showPathInputDialog(
      context,
      title: '导入配置',
      hint: '输入 JSON 配置文件路径',
    );
    if (path == null || path.isEmpty) return;

    try {
      final count = await ExportHelper.importConfig(path);
      if (context.mounted) {
        _snack(context, '导入成功，共导入 $count 项');
        // 重新加载设置
        context.read<SettingsProvider>().loadSettings();
      }
    } catch (e) {
      if (context.mounted) _snack(context, '导入失败: $e');
    }
  }

  // ── 辅助方法 ──────────────────────────────────────────────────────

  Future<String?> _showPathInputDialog(BuildContext context, {required String title, required String hint}) async {
    final ctrl = TextEditingController();
    // 预填默认路径
    final defaultPath = await ExportHelper.getDefaultExportPath();
    ctrl.text = defaultPath;

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(hintText: hint),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showExportResult(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导出成功'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('文件已保存到：'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.card2Color(ctx),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                path,
                style: TextStyle(fontSize: 13, color: AppTheme.text2(ctx)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('确定')),
        ],
      ),
    );
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppTheme.text2(context)),
      ),
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
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: Column(children: children),
      ),
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
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(title, style: TextStyle(color: AppTheme.text1(context))),
      subtitle: subtitle != null
          ? Text(subtitle!, style: TextStyle(color: AppTheme.text2(context), fontSize: 12))
          : null,
      trailing: showArrow
          ? Icon(Icons.chevron_right, color: AppTheme.text3(context), size: 20)
          : null,
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
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(title, style: TextStyle(color: AppTheme.text1(context))),
      subtitle: Text(subtitle, style: TextStyle(color: AppTheme.text2(context), fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryBlue,
      ),
    );
  }
}

Widget _Divider(BuildContext context) {
  return Divider(height: 0.5, indent: 56, color: AppTheme.separator(context));
}
