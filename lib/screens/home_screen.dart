import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/month_picker.dart';
import 'add_transaction_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: IndexedStack(
          key: ValueKey(_currentIndex),
          index: _currentIndex,
          children: const [
            _BookkeepingTab(),
            StatisticsScreen(),
            SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: '记账'),
          NavigationDestination(icon: Icon(Icons.pie_chart), selectedIcon: Icon(Icons.analytics), label: '统计'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: '设置'),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => _navigateToAdd(context),
              backgroundColor: AppTheme.primaryBlue,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
    );
  }

  void _navigateToAdd(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AddTransactionScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }
}

// ── 记账 Tab ──────────────────────────────────────────────────────────

class _BookkeepingTab extends StatelessWidget {
  const _BookkeepingTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final month = provider.selectedMonth;
        final transactions = provider.transactions;

        // 按日期分组
        final grouped = <String, List<dynamic>>{};
        for (var t in transactions) {
          final key = Formatters.date(t.date);
          grouped.putIfAbsent(key, () => []).add(t);
        }
        final dateKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

        return CustomScrollView(
          slivers: [
            // ── 顶部 App Bar ──
            SliverAppBar(
              floating: true,
              pinned: true,
              expandedHeight: 220,
              backgroundColor: AppTheme.bg(context),
              flexibleSpace: FlexibleSpaceBar(
                background: _MonthSummary(provider: provider, month: month),
              ),
              title: MonthPicker(
                selectedMonth: month,
                onMonthChanged: (m) => provider.setSelectedMonth(m),
              ),
              centerTitle: true,
            ),

            // ── 账目列表 / 空状态 ──
            if (transactions.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: AppTheme.text3(context)),
                      const SizedBox(height: 16),
                      Text('本月还没有记录',
                          style: TextStyle(color: AppTheme.text2(context), fontSize: 17)),
                      const SizedBox(height: 8),
                      Text('点击 + 开始记账',
                          style: TextStyle(color: AppTheme.text3(context), fontSize: 15)),
                    ],
                  ),
                ),
              )
            else
              SliverList.builder(
                itemCount: dateKeys.length,
                itemBuilder: (context, index) {
                  final dateKey = dateKeys[index];
                  final dayTransactions = grouped[dateKey]!;
                  final date = dayTransactions.first.date;

                  double dayExpense = 0, dayIncome = 0;
                  for (var t in dayTransactions) {
                    if (t.isExpense) dayExpense += t.amount;
                    else dayIncome += t.amount;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 日期头部
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${Formatters.day(date)} ${Formatters.shortWeekday(date)}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.text2(context),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '支出 ${Formatters.currency(dayExpense)}  收入 ${Formatters.currency(dayIncome)}',
                              style: TextStyle(fontSize: 13, color: AppTheme.text3(context)),
                            ),
                          ],
                        ),
                      ),
                      // 当日账目
                      ...dayTransactions.map((t) => TransactionTile(
                            transaction: t,
                            onTap: () => _editTransaction(context, t),
                            onDelete: () => _deleteTransaction(context, provider, t),
                          )),
                    ],
                  );
                },
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      },
    );
  }

  void _editTransaction(BuildContext context, dynamic t) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddTransactionScreen(editTransaction: t)),
    );
  }

  void _deleteTransaction(BuildContext context, TransactionProvider provider, dynamic t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后无法恢复，确定要删除吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              provider.deleteTransaction(t.id);
              Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: AppTheme.destructiveRed)),
          ),
        ],
      ),
    );
  }
}

// ── 月度汇总卡片 ──────────────────────────────────────────────────────

class _MonthSummary extends StatelessWidget {
  final TransactionProvider provider;
  final DateTime month;

  const _MonthSummary({required this.provider, required this.month});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: provider.getMonthlySummary(month.year, month.month),
      builder: (context, snapshot) {
        final expense = snapshot.data?['expense'] ?? 0;
        final income = snapshot.data?['income'] ?? 0;
        final balance = income - expense;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('本月结余',
                  style: TextStyle(color: AppTheme.text2(context), fontSize: 14)),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  Formatters.currency(balance),
                  key: ValueKey(balance),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: balance >= 0 ? AppTheme.successGreen : AppTheme.destructiveRed,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SummaryItem(
                      label: '收入',
                      amount: income,
                      color: AppTheme.successGreen,
                    ),
                  ),
                  Container(
                    width: 0.5,
                    height: 30,
                    color: AppTheme.separator(context),
                  ),
                  Expanded(
                    child: _SummaryItem(
                      label: '支出',
                      amount: expense,
                      color: AppTheme.destructiveRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: AppTheme.text2(context), fontSize: 13)),
        const SizedBox(height: 4),
        Text(
          Formatters.currency(amount),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}
