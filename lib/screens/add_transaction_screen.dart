import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

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
      _amountCtrl.text = t.amount.toStringAsFixed(2);
      _noteCtrl.text = t.note ?? '';
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
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: Text(_isEditing ? '编辑账目' : '记一笔'),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存', style: TextStyle(fontWeight: FontWeight.w600)),
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

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAmountInput(),
                  const SizedBox(height: 16),
                  _buildCategorySelector(),
                  const SizedBox(height: 16),
                  _buildTagSelector(),
                  const SizedBox(height: 16),
                  _buildNoteInput(),
                  const SizedBox(height: 16),
                  _buildDateSelector(),
                  if (_isEditing) ...[
                    const SizedBox(height: 40),
                    _buildDeleteButton(),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 金额输入 ──
  Widget _buildAmountInput() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('金额', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.text2(context))),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('¥', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.text1(context))),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                  style: TextStyle(fontSize: 42, fontWeight: FontWeight.w700, color: AppTheme.text1(context)),
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

  // ── 分类选择 ──
  Widget _buildCategorySelector() {
    return Consumer<CategoryProvider>(
      builder: (context, catProvider, _) {
        final categories = _isExpense ? catProvider.expenseCategories : catProvider.incomeCategories;

        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('分类', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.text2(context))),
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
                itemBuilder: (_, index) {
                  final cat = categories[index];
                  final selected = _selectedCategory == cat.name;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat.name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: selected ? cat.color.withOpacity(0.2) : AppTheme.card2Color(context),
                              borderRadius: BorderRadius.circular(12),
                              border: selected ? Border.all(color: cat.color, width: 2) : null,
                            ),
                            child: Icon(cat.icon, color: selected ? cat.color : AppTheme.text2(context), size: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: selected ? cat.color : AppTheme.text2(context),
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
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

  // ── 标签选择 ──
  Widget _buildTagSelector() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('标签', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.text2(context))),
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

  // ── 备注 ──
  Widget _buildNoteInput() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('备注', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.text2(context))),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            style: TextStyle(color: AppTheme.text1(context)),
            decoration: InputDecoration(
              hintText: '添加备注...',
              hintStyle: TextStyle(color: AppTheme.text3(context)),
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

  // ── 日期选择 ──
  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _pickDate,
      child: _Card(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('日期', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.text2(context))),
            Row(
              children: [
                Text(
                  '${Formatters.date(_selectedDate)} ${Formatters.shortWeekday(_selectedDate)}',
                  style: TextStyle(fontSize: 15, color: AppTheme.text1(context)),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: AppTheme.text3(context), size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 通用卡片包装 ──
  Widget _Card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  // ── 删除按钮 ──
  Widget _buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: _delete,
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.destructiveRed,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('删除此账目', style: TextStyle(fontSize: 17)),
      ),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后无法恢复，确定要删除吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: AppTheme.destructiveRed)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<TransactionProvider>();
      await provider.deleteTransaction(widget.editTransaction!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _showAddTagDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加标签'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: '输入标签名称'), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              final tag = ctrl.text.trim();
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
    final amountText = _amountCtrl.text.trim();
    if (amountText.isEmpty) return _error('请输入金额');

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return _error('请输入有效金额');
    if (_selectedCategory == null) return _error('请选择分类');

    final provider = context.read<TransactionProvider>();

    if (_isEditing) {
      await provider.updateTransaction(widget.editTransaction!.copyWith(
        amount: amount,
        isExpense: _isExpense,
        category: _selectedCategory!,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        tags: _selectedTags,
        date: _selectedDate,
      ));
    } else {
      await provider.quickAdd(
        amount: amount,
        isExpense: _isExpense,
        category: _selectedCategory!,
        tags: _selectedTags,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.destructiveRed),
    );
  }
}
