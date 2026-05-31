import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';

class MonthPicker extends StatelessWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;

  const MonthPicker({
    super.key,
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.card2Color(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Formatters.month(selectedMonth),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.text1(context),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: AppTheme.text2(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    int tempYear = selectedMonth.year;
    int tempMonth = selectedMonth.month;

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          height: 300,
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.separator(ctx).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              // Action bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        onMonthChanged(DateTime(tempYear, tempMonth));
                        Navigator.pop(ctx);
                      },
                      child: const Text('确定', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0.5),
              // Pickers
              Expanded(
                child: StatefulBuilder(
                  builder: (ctx, setState) {
                    return Row(
                      children: [
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: tempYear - 2020,
                            ),
                            itemExtent: 44,
                            onSelectedItemChanged: (i) => setState(() => tempYear = 2020 + i),
                            children: List.generate(20, (i) {
                              return Center(
                                child: Text('${2020 + i}年',
                                    style: const TextStyle(fontSize: 20)),
                              );
                            }),
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: tempMonth - 1,
                            ),
                            itemExtent: 44,
                            onSelectedItemChanged: (i) => setState(() => tempMonth = i + 1),
                            children: List.generate(12, (i) {
                              return Center(
                                child: Text('${i + 1}月',
                                    style: const TextStyle(fontSize: 20)),
                              );
                            }),
                          ),
                        ),
                      ],
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
