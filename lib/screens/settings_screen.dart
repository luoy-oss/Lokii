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
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const SizedBox(height: 20),

          // 自动记账开关
          _buildSection(
            title: '自动记账',
            children: [
              Consumer<SettingsProvider>(
                builder: (context, settings, _) {
                  return _buildSwitchTile(
                    icon: Icons.notifications_active,
                    iconColor: AppTheme.warningOrange,
                    title: '通知自动记账',
                    subtitle: '读取支付通知自动记录账目',
                    value: settings.autoRecordEnabled,
                    onChanged: (v) => settings.setAutoRecordEnabled(v),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 数据管理
          _buildSection(
            title: '数据管理',
            children: [
              _buildTile(
                icon: Icons.download,
                iconColor: AppTheme.primaryBlue,
                title: '导出本月数据',
                onTap: () => _exportCurrentMonth(context),
              ),
              const Divider(height: 0.5, indent: 56),
              _buildTile(
                icon: Icons.calendar_month,
                iconColor: AppTheme.successGreen,
                title: '导出指定月份',
                onTap: () => _exportByMonth(context),
              ),
              const Divider(height: 0.5, indent: 56),
              _buildTile(
                icon: Icons.all_inclusive,
                iconColor: AppTheme.destructiveRed,
                title: '导出全部数据',
                onTap: () => _exportAll(context),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 标签管理
          _buildSection(
            title: '标签管理',
            children: [
              _buildTile(
                icon: Icons.label,
                iconColor: AppTheme.primaryBlue,
                title: '管理标签',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TagManageScreen()),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 关于
          _buildSection(
            title: '关于',
            children: [
              _buildTile(
                icon: Icons.info_outline,
                iconColor: AppTheme.textSecondary,
                title: 'Lokii 记账',
                subtitle: 'v1.0.0',
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryBlue,
      ),
    );
  }

  Future<void> _exportCurrentMonth(BuildContext context) async {
    final provider = context.read<TransactionProvider>();
    final now = DateTime.now();
    final transactions = await provider.getAllTransactions(
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
    if (transactions.isEmpty) {
      _showSnackBar(context, '本月没有数据可导出');
      return;
    }
    await ExportHelper.exportAndShare(transactions, dateRange: Formatters.month(now));
    _showSnackBar(context, '导出成功');
  }

  Future<void> _exportByMonth(BuildContext context) async {
    // 简化实现：导出上个月
    final provider = context.read<TransactionProvider>();
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    final transactions = await provider.getAllTransactions(
      startDate: DateTime(lastMonth.year, lastMonth.month, 1),
      endDate: DateTime(lastMonth.year, lastMonth.month + 1, 0, 23, 59, 59),
    );
    if (transactions.isEmpty) {
      _showSnackBar(context, '上月没有数据可导出');
      return;
    }
    await ExportHelper.exportAndShare(transactions, dateRange: Formatters.month(lastMonth));
    _showSnackBar(context, '导出成功');
  }

  Future<void> _exportAll(BuildContext context) async {
    final provider = context.read<TransactionProvider>();
    final transactions = await provider.getAllTransactions();
    if (transactions.isEmpty) {
      _showSnackBar(context, '没有数据可导出');
      return;
    }
    await ExportHelper.exportAndShare(transactions, dateRange: '全部');
    _showSnackBar(context, '导出成功');
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
