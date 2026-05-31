import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
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
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(title: Text(categoryName)),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          return FutureBuilder<List<dynamic>>(
            future: provider.getTransactionsByCategory(categoryName, year: year, month: month),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text('暂无记录', style: TextStyle(color: AppTheme.text2(context))),
                );
              }

              final transactions = snapshot.data!;
              final total = transactions.fold(0.0, (s, t) => s + t.amount);

              final grouped = <String, List<dynamic>>{};
              for (var t in transactions) {
                grouped.putIfAbsent(Formatters.date(t.date), () => []).add(t);
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
                        color: AppTheme.cardColor(context),
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
                                style: TextStyle(fontSize: 15, color: AppTheme.text2(context)),
                              ),
                              const SizedBox(height: 4),
                              Text('${transactions.length} 笔',
                                  style: TextStyle(fontSize: 13, color: AppTheme.text3(context))),
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

                  SliverList.builder(
                    itemCount: dateKeys.length,
                    itemBuilder: (context, index) {
                      final dateKey = dateKeys[index];
                      final dayTxns = grouped[dateKey]!;
                      final date = dayTxns.first.date;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              '${Formatters.day(date)} ${Formatters.shortWeekday(date)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.text2(context),
                              ),
                            ),
                          ),
                          ...dayTxns.map((t) => TransactionTile(
                                transaction: t,
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => AddTransactionScreen(editTransaction: t))),
                                onDelete: () => provider.deleteTransaction(t.id),
                              )),
                        ],
                      );
                    },
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
