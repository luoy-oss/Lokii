import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';

class CategoryDetailScreen extends StatelessWidget {
  final String categoryName;
  final bool isExpense;
  final int year;
  final int month;

  const CategoryDetailScreen({
    super.key,
    required this.categoryName,
    required this.isExpense,
    required this.year,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: Text(categoryName),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          return FutureBuilder<List<dynamic>>(
            future: provider.getTransactionsByCategory(categoryName, year: year, month: month),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('暂无记录', style: TextStyle(color: AppTheme.textSecondary)),
                );
              }

              final transactions = snapshot.data!;
              final total = transactions.fold(0.0, (sum, t) => sum + t.amount);

              // 按日期分组
              final grouped = <String, List<dynamic>>{};
              for (var t in transactions) {
                final key = Formatters.date(t.date);
                grouped.putIfAbsent(key, () => []).add(t);
              }
              final dateKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

              return CustomScrollView(
                slivers: [
                  // 顶部汇总
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${Formatters.month(DateTime(year, month))} $categoryName',
                                style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${transactions.length} 笔',
                                style: const TextStyle(fontSize: 13, color: AppTheme.textTertiary),
                              ),
                            ],
                          ),
                          Text(
                            Formatters.currency(total),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: isExpense ? AppTheme.destructiveRed : AppTheme.successGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 账目列表
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= dateKeys.length) return null;
                        final dateKey = dateKeys[index];
                        final dayTransactions = grouped[dateKey]!;
                        final date = dayTransactions.first.date;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                '${Formatters.day(date)} ${Formatters.shortWeekday(date)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            ...dayTransactions.map((t) => TransactionTile(
                                  transaction: t,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddTransactionScreen(editTransaction: t),
                                      ),
                                    );
                                  },
                                  onDelete: () => provider.deleteTransaction(t.id),
                                )),
                          ],
                        );
                      },
                      childCount: dateKeys.length,
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
