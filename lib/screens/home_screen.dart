import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import '../widgets/transaction_tile.dart';
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
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _BookkeepingTab(),
          StatisticsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.separatorGray, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: '记账'),
            BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: '统计'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
          ],
        ),
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
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
  }
}

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
            // 顶部 App Bar
            SliverAppBar(
              floating: true,
              pinned: true,
              expandedHeight: 240,
              backgroundColor: AppTheme.backgroundGray,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildMonthSummary(context, provider, month),
              ),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 28),
                    onPressed: () => provider.previousMonth(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Formatters.month(month),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 28),
                    onPressed: () => provider.nextMonth(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              centerTitle: true,
            ),

            // 账目列表
            if (transactions.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: AppTheme.textTertiary),
                      SizedBox(height: 16),
                      Text('本月还没有记录', style: TextStyle(color: AppTheme.textSecondary, fontSize: 17)),
                      SizedBox(height: 8),
                      Text('点击 + 开始记账', style: TextStyle(color: AppTheme.textTertiary, fontSize: 15)),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= dateKeys.length) return null;
                    final dateKey = dateKeys[index];
                    final dayTransactions = grouped[dateKey]!;
                    final date = dayTransactions.first.date;

                    // 计算当日收支
                    double dayExpense = 0;
                    double dayIncome = 0;
                    for (var t in dayTransactions) {
                      if (t.isExpense) {
                        dayExpense += t.amount;
                      } else {
                        dayIncome += t.amount;
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 日期头部
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  '${Formatters.day(date)} ${Formatters.shortWeekday(date)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '支出 ${Formatters.currency(dayExpense)}  收入 ${Formatters.currency(dayIncome)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textTertiary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 当日账目列表
                        ...dayTransactions.map((t) => TransactionTile(
                              transaction: t,
                              onTap: () => _editTransaction(context, t),
                              onDelete: () => _deleteTransaction(context, provider, t),
                            )),
                      ],
                    );
                  },
                  childCount: dateKeys.length,
                ),
              ),

            // 底部留白
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      },
    );
  }

  Widget _buildMonthSummary(BuildContext context, TransactionProvider provider, DateTime month) {
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
              const Text('本月结余', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                Formatters.currency(balance),
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: balance >= 0 ? AppTheme.successGreen : AppTheme.destructiveRed,
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
                  Container(width: 0.5, height: 30, color: AppTheme.separatorGray),
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

  void _editTransaction(BuildContext context, dynamic transaction) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(editTransaction: transaction),
      ),
    );
  }

  void _deleteTransaction(BuildContext context, TransactionProvider provider, dynamic transaction) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后无法恢复，确定要删除吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              provider.deleteTransaction(transaction.id);
              Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: AppTheme.destructiveRed)),
          ),
        ],
      ),
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
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 4),
        Text(
          Formatters.currency(amount),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}
