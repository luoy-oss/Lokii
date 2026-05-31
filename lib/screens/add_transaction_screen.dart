import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import '../widgets/quick_tag_selector.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? editTransaction;

  const AddTransactionScreen({super.key, this.editTransaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isExpense = true;
  String? _selectedCategory;
  List<String> _selectedTags = [];
  DateTime _selectedDate = DateTime.now();

  bool get _isEditing => widget.editTransaction != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (_isEditing) {
      final t = widget.editTransaction!;
      _amountController.text = t.amount.toStringAsFixed(2);
      _noteController.text = t.note ?? '';
      _isExpense = t.isExpense;
      _selectedCategory = t.category;
      _selectedTags = List.from(t.tags);
      _selectedDate = t.date;
      _tabController.index = _isExpense ? 0 : 1;
    }

    _tabController.addListener(() {
      setState(() {
        _isExpense = _tabController.index == 0;
        _selectedCategory = null;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: Text(_isEditing ? '编辑账目' : '记一笔'),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消', style: TextStyle(color: AppTheme.primaryBlue)),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w600)),
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
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: '支出'),
                Tab(text: '收入'),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 金额输入
                  _buildAmountInput(),
                  const SizedBox(height: 20),

                  // 分类选择
                  _buildCategorySelector(),
                  const SizedBox(height: 20),

                  // 标签选择
                  _buildTagSelector(),
                  const SizedBox(height: 20),

                  // 备注
                  _buildNoteInput(),
                  const SizedBox(height: 20),

                  // 日期选择
                  _buildDateSelector(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('金额', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('¥', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                  autofocus: !_isEditing,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Consumer<CategoryProvider>(
      builder: (context, catProvider, _) {
        final categories = _isExpense ? catProvider.expenseCategories : catProvider.incomeCategories;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('分类', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedCategory == cat.name;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat.name),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected ? cat.color.withOpacity(0.2) : const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(color: cat.color, width: 2)
                                : null,
                          ),
                          child: Icon(cat.icon, color: isSelected ? cat.color : AppTheme.textSecondary, size: 24),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? cat.color : AppTheme.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTagSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('标签', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
              TextButton(
                onPressed: _showAddTagDialog,
                child: const Text('自定义', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          QuickTagSelector(
            selectedTags: _selectedTags,
            onTagToggle: (tag) {
              setState(() {
                if (_selectedTags.contains(tag)) {
                  _selectedTags.remove(tag);
                } else {
                  _selectedTags.add(tag);
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoteInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('备注', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: '添加备注...',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('日期', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
            Row(
              children: [
                Text(
                  '${Formatters.date(_selectedDate)} ${Formatters.shortWeekday(_selectedDate)}',
                  style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: AppTheme.textTertiary, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showAddTagDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加标签'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '输入标签名称'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              final tag = controller.text.trim();
              if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
                setState(() => _selectedTags.add(tag));
              }
              Navigator.pop(ctx);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      _showError('请输入金额');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('请输入有效金额');
      return;
    }

    if (_selectedCategory == null) {
      _showError('请选择分类');
      return;
    }

    final provider = context.read<TransactionProvider>();

    if (_isEditing) {
      final updated = widget.editTransaction!.copyWith(
        amount: amount,
        isExpense: _isExpense,
        category: _selectedCategory!,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        tags: _selectedTags,
        date: _selectedDate,
      );
      await provider.updateTransaction(updated);
    } else {
      await provider.quickAdd(
        amount: amount,
        isExpense: _isExpense,
        category: _selectedCategory!,
        tags: _selectedTags,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.destructiveRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
