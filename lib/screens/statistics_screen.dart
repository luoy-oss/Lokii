import 'package:flutter/cupertino.dart';
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

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
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
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: const Text('统计'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _isMonthlyView = !_isMonthlyView),
            child: Text(_isMonthlyView ? '年度' : '月度'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 收入/支出 Tab
          Container(
            color: AppTheme.cardColor(context),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: AppTheme.text2(context),
              indicatorColor: AppTheme.primaryBlue,
              dividerColor: Colors.transparent,
              tabs: const [Tab(text: '支出'), Tab(text: '收入')],
            ),
          ),
          // 时间选择
          _TimeSelector(
            isMonthly: _isMonthlyView,
            month: _selectedMonth,
            year: _selectedYear,
            onPrev: () => setState(() {
              if (_isMonthlyView) {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
              } else {
                _selectedYear--;
              }
            }),
            onNext: () => setState(() {
              if (_isMonthlyView) {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
              } else {
                _selectedYear++;
              }
            }),
            onMonthPicked: (m) => setState(() => _selectedMonth = m),
            onYearPicked: (y) => setState(() => _selectedYear = y),
          ),
          Expanded(
            child: _isMonthlyView ? _buildMonthlyView() : _buildYearlyView(),
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
              return Center(
                child: Text('暂无数据', style: TextStyle(color: AppTheme.text2(context))),
              );
            }

            final data = snapshot.data!;
            final total = data.values.fold(0.0, (s, v) => s + v);
            final entries = data.entries.toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 饼图
                Container(
                  height: 220,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: PieChart(
                    PieChartData(
                      sections: _pieSections(entries, total, isExpense),
                      centerSpaceRadius: 45,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 总计
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isExpense ? '总支出' : '总收入',
                          style: TextStyle(fontSize: 15, color: AppTheme.text2(context))),
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
                const SizedBox(height: 12),

                // 分类列表
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      children: entries.map((e) {
                        final pct = (e.value / total * 100);
                        final cat = context.read<CategoryProvider>().findByName(
                              e.key,
                              isExpense: isExpense,
                            );
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: (cat?.color ?? AppTheme.text3(context)).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(cat?.icon ?? Icons.category,
                                color: cat?.color ?? AppTheme.text3(context), size: 20),
                          ),
                          title: Text(e.key,
                              style: TextStyle(color: AppTheme.text1(context))),
                          subtitle: Text('${pct.toStringAsFixed(1)}%',
                              style: TextStyle(color: AppTheme.text2(context))),
                          trailing: Text(
                            Formatters.currency(e.value),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: AppTheme.text1(context),
                            ),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CategoryDetailScreen(
                                categoryName: e.key,
                                isExpense: isExpense,
                                year: _selectedMonth.year,
                                month: _selectedMonth.month,
                              ),
                            ),
                          ),
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
              return Center(
                child: Text('暂无数据', style: TextStyle(color: AppTheme.text2(context))),
              );
            }

            final data = snapshot.data!;
            final monthly = List.filled(12, 0.0);
            for (var row in data) {
              monthly[int.parse(row['month'] as String) - 1] =
                  (row['total'] as num).toDouble();
            }
            final yearTotal = monthly.fold(0.0, (s, v) => s + v);
            final maxY = monthly.reduce((a, b) => a > b ? a : b) * 1.2;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 年度总计
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(isExpense ? '年度总支出' : '年度总收入',
                          style: TextStyle(fontSize: 15, color: AppTheme.text2(context))),
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
                const SizedBox(height: 12),

                // 柱状图
                Container(
                  height: 240,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY > 0 ? maxY : 100,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (g, _, rod, __) => BarTooltipItem(
                            Formatters.currency(rod.toY),
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) => Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text('${v.toInt() + 1}月',
                                  style: TextStyle(
                                      fontSize: 11, color: AppTheme.text3(context))),
                            ),
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
                              toY: monthly[i],
                              color: isExpense ? AppTheme.destructiveRed : AppTheme.successGreen,
                              width: 18,
                              borderRadius:
                                  const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 月度明细
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      children: List.generate(12, (i) {
                        return ListTile(
                          title: Text('${i + 1}月',
                              style: TextStyle(color: AppTheme.text1(context))),
                          trailing: Text(
                            Formatters.currency(monthly[i]),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.text1(context),
                            ),
                          ),
                          onTap: () => setState(() {
                            _isMonthlyView = true;
                            _selectedMonth = DateTime(_selectedYear, i + 1);
                          }),
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

  List<PieChartSectionData> _pieSections(
    List<MapEntry<String, double>> entries,
    double total,
    bool isExpense,
  ) {
    const colors = [
      Color(0xFFFF6B6B), Color(0xFF4ECDC4), Color(0xFFFFBE76),
      Color(0xFF6C5CE7), Color(0xFFFD79A8), Color(0xFF00B894),
      Color(0xFF0984E3), Color(0xFF636E72), Color(0xFFE17055),
      Color(0xFF00CEC9),
    ];
    return entries.asMap().entries.map((e) {
      return PieChartSectionData(
        value: e.value.value,
        title: '${(e.value.value / total * 100).toStringAsFixed(0)}%',
        color: colors[e.key % colors.length],
        radius: 48,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
      );
    }).toList();
  }
}

// ── 时间选择器 ────────────────────────────────────────────────────────

class _TimeSelector extends StatelessWidget {
  final bool isMonthly;
  final DateTime month;
  final int year;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime>? onMonthPicked;
  final ValueChanged<int>? onYearPicked;

  const _TimeSelector({
    required this.isMonthly,
    required this.month,
    required this.year,
    required this.onPrev,
    required this.onNext,
    this.onMonthPicked,
    this.onYearPicked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.cardColor(context),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrev),
          const SizedBox(width: 16),
          GestureDetector(
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
                    isMonthly ? Formatters.month(month) : '$year年',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.text1(context),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, size: 20, color: AppTheme.text2(context)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context) {
    int tempYear = isMonthly ? month.year : year;
    int tempMonth = month.month;

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
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 36, height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.separator(ctx).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                    TextButton(
                      onPressed: () {
                        if (isMonthly && onMonthPicked != null) {
                          onMonthPicked!(DateTime(tempYear, tempMonth));
                        } else if (!isMonthly && onYearPicked != null) {
                          onYearPicked!(tempYear);
                        }
                        Navigator.pop(ctx);
                      },
                      child: const Text('确定', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0.5),
              Expanded(
                child: StatefulBuilder(
                  builder: (ctx, setState) {
                    return Row(
                      children: [
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(initialItem: tempYear - 2020),
                            itemExtent: 44,
                            onSelectedItemChanged: (i) => setState(() => tempYear = 2020 + i),
                            children: List.generate(20, (i) =>
                              Center(child: Text('${2020 + i}年', style: const TextStyle(fontSize: 20)))),
                          ),
                        ),
                        if (isMonthly)
                          Expanded(
                            child: CupertinoPicker(
                              scrollController: FixedExtentScrollController(initialItem: tempMonth - 1),
                              itemExtent: 44,
                              onSelectedItemChanged: (i) => setState(() => tempMonth = i + 1),
                              children: List.generate(12, (i) =>
                                Center(child: Text('${i + 1}月', style: const TextStyle(fontSize: 20)))),
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
