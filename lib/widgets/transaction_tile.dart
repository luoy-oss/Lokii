import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/category_provider.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppTheme.destructiveRed,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('确定要删除这条记录吗？'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('删除', style: TextStyle(color: AppTheme.destructiveRed)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete?.call(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: _buildCategoryIcon(context),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  transaction.category,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
              Text(
                Formatters.currencyWithSign(
                  transaction.amount,
                  isExpense: transaction.isExpense,
                ),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: transaction.isExpense ? AppTheme.destructiveRed : AppTheme.successGreen,
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (transaction.note != null && transaction.note!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  transaction.note!,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (transaction.tags.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: transaction.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(fontSize: 12, color: AppTheme.primaryBlue),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
          onTap: onTap,
        ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(BuildContext context) {
    final catProvider = context.read<CategoryProvider>();
    final cat = catProvider.findByName(
      transaction.category,
      isExpense: transaction.isExpense,
    );

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: (cat?.color ?? AppTheme.textTertiary).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        cat?.icon ?? Icons.category,
        color: cat?.color ?? AppTheme.textTertiary,
        size: 22,
      ),
    );
  }
}
