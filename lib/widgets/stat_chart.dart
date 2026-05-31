import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/theme.dart';

class StatChart extends StatelessWidget {
  final List<double> monthlyData;
  final bool isExpense;
  final int year;

  const StatChart({
    super.key,
    required this.monthlyData,
    required this.isExpense,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    final maxY = monthlyData.reduce((a, b) => a > b ? a : b) * 1.2;
    final color = isExpense ? AppTheme.destructiveRed : AppTheme.successGreen;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY > 0 ? maxY : 100,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.toStringAsFixed(2),
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${value.toInt() + 1}月',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: List.generate(12, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: monthlyData[i],
                color: color,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }
}
