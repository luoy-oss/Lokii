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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              onMonthChanged(DateTime(
                selectedMonth.year,
                selectedMonth.month - 1,
              ));
            },
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => _showMonthPickerDialog(context),
            child: Text(
              Formatters.month(selectedMonth),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              onMonthChanged(DateTime(
                selectedMonth.year,
                selectedMonth.month + 1,
              ));
            },
          ),
        ],
      ),
    );
  }

  void _showMonthPickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        int selectedYear = selectedMonth.year;
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(() => selectedYear--),
                  ),
                  Text('$selectedYear年', style: const TextStyle(fontSize: 17)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setState(() => selectedYear++),
                  ),
                ],
              ),
              content: SizedBox(
                width: 300,
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: 12,
                  itemBuilder: (ctx, index) {
                    final month = index + 1;
                    final isSelected = selectedYear == selectedMonth.year &&
                        month == selectedMonth.month;

                    return GestureDetector(
                      onTap: () {
                        onMonthChanged(DateTime(selectedYear, month));
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryBlue : const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$month月',
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
