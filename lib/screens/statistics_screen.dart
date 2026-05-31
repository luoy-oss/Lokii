import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import 'category_detail_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();
  int _selectedYear = DateTime.now().year;
  bool _isMonthlyView = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: const Text('统计'),
        actions: [
          // 月度/年度切换
          TextButton(
            onPressed: () => setState(() => _isMonthlyView = !_isMonthlyView),
            child: Text(
              _isMonthlyView ? '年度' : '月度',
              style: const TextStyle(color: AppTheme.primaryBlue),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 收入/支出切换
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primaryBlue,
              tabs: const [
                Tab(text: '支出'),
                Tab(text: '收入'),
              ],
            ),
          ),
          // 时间选择器
          _buildTimeSelector(),
          Expanded(
            child: _isMonthlyView ? _buildMonthlyView() : _buildYearlyView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                if (_isMonthlyView) {
                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                } else {
                  _selectedYear--;
                }
              });
            },
          ),
          const SizedBox(width: 16),
          Text(
            _isMonthlyView ? Formatters.month(_selectedMonth) : '$_selectedYear年',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                if (_isMonthlyView) {
                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                } else {
                  _selectedYear++;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyView() {
    final isExpense = _tabController.index == 0;
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        return FutureBuilder<Map<String, double>>(
          future: provider.getCategorySummary(
            year: _selectedMonth.year,
            month: _selectedMonth.month,
            isExpense: isExpense,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('暂无数据', style: TextStyle(color: AppTheme.textSecondary)),
              );
            }

            final data = snapshot.data!;
            final total = data.values.fold(0.0, (sum, v) => sum + v);
            final entries = data.entries.toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 饼图
                Container(
                  height: 240,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: PieChart(
                    PieChartData(
                      sections: _buildPieSections(entries, total, isExpense),
                      centerSpaceRadius: 50,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 总计
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isExpense ? '总支出' : '总收入',
                        style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary),
                      ),
                      Text(
                        Formatters.currency(total),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isExpense ? AppTheme.destructiveRed : AppTheme.successGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 分类列表
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                    children: entries.map((entry) {
                      final percentage = (entry.value / total * 100);
                      final catProvider = context.read<CategoryProvider>();
                      final cat = catProvider.findByName(entry.key, isExpense: isExpense);

                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: (cat?.color ?? AppTheme.textTertiary).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            cat?.icon ?? Icons.category,
                            color: cat?.color ?? AppTheme.textTertiary,
                            size: 20,
                          ),
                        ),
                        title: Text(entry.key),
                        subtitle: Text('${percentage.toStringAsFixed(1)}%'),
                        trailing: Text(
                          Formatters.currency(entry.value),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CategoryDetailScreen(
                                categoryName: entry.key,
                                isExpense: isExpense,
                                year: _selectedMonth.year,
                                month: _selectedMonth.month,
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildYearlyView() {
    final isExpense = _tabController.index == 0;
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: provider.getYearlyMonthlyTotals(_selectedYear, isExpense: isExpense),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('暂无数据', style: TextStyle(color: AppTheme.textSecondary)),
              );
            }

            final data = snapshot.data!;
            final monthlyTotals = List.filled(12, 0.0);
            for (var row in data) {
              final month = int.parse(row['month'] as String) - 1;
              monthlyTotals[month] = (row['total'] as num).toDouble();
            }
            final yearTotal = monthlyTotals.fold(0.0, (sum, v) => sum + v);
            final maxY = monthlyTotals.reduce((a, b) => a > b ? a : b) * 1.2;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 年度总计
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isExpense ? '年度总支出' : '年度总收入',
                        style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Formatters.currency(yearTotal),
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: isExpense ? AppTheme.destructiveRed : AppTheme.successGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 柱状图
                Container(
                  height: 260,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY > 0 ? maxY : 100,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              Formatters.currency(rod.toY),
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
                              toY: monthlyTotals[i],
                              color: isExpense ? AppTheme.destructiveRed : AppTheme.successGreen,
                              width: 20,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 月度明细
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                    children: List.generate(12, (i) {
                      return ListTile(
                        title: Text('${i + 1}月'),
                        trailing: Text(
                          Formatters.currency(monthlyTotals[i]),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onTap: () {
                          setState(() {
                            _isMonthlyView = true;
                            _selectedMonth = DateTime(_selectedYear, i + 1);
                          });
                        },
                      );
                    }),
                  ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<PieChartSectionData> _buildPieSections(
    List<MapEntry<String, double>> entries,
    double total,
    bool isExpense,
  ) {
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFFFFBE76),
      const Color(0xFF6C5CE7),
      const Color(0xFFFD79A8),
      const Color(0xFF00B894),
      const Color(0xFF0984E3),
      const Color(0xFF636E72),
      const Color(0xFFE17055),
      const Color(0xFF00CEC9),
    ];

    return entries.asMap().entries.map((mapEntry) {
      final index = mapEntry.key;
      final entry = mapEntry.value;
      final percentage = (entry.value / total * 100);

      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        color: colors[index % colors.length],
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}
