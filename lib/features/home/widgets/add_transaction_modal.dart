import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme.dart';
import '../models/transaction.dart';

class AddTransactionModal extends StatefulWidget {
  const AddTransactionModal({super.key, required this.onSubmit, this.initial});

  final ValueChanged<TransactionFormData> onSubmit;
  final Transaction? initial;

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  TransactionType _type = TransactionType.expense;
  String _description = '';
  String _amount = '';
  DateTime _date = DateTime.now();
  String _category = 'other';
  bool _showCategoryPicker = false;
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _type = initial.type;
      _description = initial.title;
      _amount = initial.amount.toStringAsFixed(2);
      _date = initial.date;
      _category = _categoryIdFromLabel(initial.category);
    }
    _descriptionController = TextEditingController(text: _description);
    _amountController = TextEditingController(text: _amount);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = _categories.firstWhere(
      (c) => c.id == _category,
      orElse: () => _categories.last,
    );
    final isEditing = widget.initial != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF141414),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.modalTop),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Transaction' : 'Add Transaction',
                      style: AppTextStyles.modalTitle,
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _sectionLabel('Transaction Type'),
                const SizedBox(height: 10),
                Row(
                  children: _typeOptions.map((option) {
                    final isSelected = option.type == _type;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _TypeTile(
                          option: option,
                          isSelected: isSelected,
                          onTap: () => setState(() => _type = option.type),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                _sectionLabel('Category'),
                const SizedBox(height: 8),
                _categorySelector(selectedCategory),
                if (_showCategoryPicker) ...[
                  const SizedBox(height: 10),
                  _categoryGrid(),
                ],
                const SizedBox(height: 16),
                _sectionLabel('Description'),
                const SizedBox(height: 8),
                _textField(
                  hint: 'e.g., Monthly salary, Grocery shopping...',
                  icon: Icons.description_outlined,
                  controller: _descriptionController,
                  onChanged: (value) => setState(() => _description = value),
                ),
                const SizedBox(height: 16),
                _sectionLabel('Amount'),
                const SizedBox(height: 8),
                _textField(
                  hint: '0.00',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  prefixText: '${AppConstants.currencySymbol} ',
                  controller: _amountController,
                  onChanged: (value) => setState(() => _amount = value),
                ),
                const SizedBox(height: 16),
                _sectionLabel('Date'),
                const SizedBox(height: 8),
                _dateField(),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _description.isEmpty || _amount.isEmpty
                        ? null
                        : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.large),
                      ),
                    ),
                    child: Text(
                      isEditing ? 'Update Transaction' : 'Add Transaction',
                      style: AppTextStyles.buttonLabel.copyWith(
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.formLabel.copyWith(color: AppColors.textSecondary),
    );
  }

  Widget _textField({
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? prefixText,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: AppTextStyles.inputText,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textTertiary),
        prefixText: prefixText,
      ),
    );
  }

  Widget _dateField() {
    final formatted =
        '${_date.month.toString().padLeft(2, '0')}/${_date.day.toString().padLeft(2, '0')}/${_date.year}';
    return GestureDetector(
      onTap: _pickDate,
      child: AbsorbPointer(
        child: TextField(
          decoration: InputDecoration(
            hintText: formatted,
            prefixIcon: const Icon(
              Icons.calendar_month,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _categorySelector(_CategoryOption selected) {
    return GestureDetector(
      onTap: () => setState(() => _showCategoryPicker = !_showCategoryPicker),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    selected.icon,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(selected.label, style: AppTextStyles.inputText),
              ],
            ),
            Icon(
              _showCategoryPicker ? Icons.expand_less : Icons.expand_more,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryGrid() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: GridView.count(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: _categories.map((cat) {
          final isSelected = cat.id == _category;
          return GestureDetector(
            onTap: () => setState(() {
              _category = cat.id;
              _showCategoryPicker = false;
            }),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.large),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    cat.icon,
                    size: 20,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cat.label,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.primary,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _submit() {
    final amount = double.tryParse(_amount) ?? 0;
    widget.onSubmit(
      TransactionFormData(
        id: widget.initial?.id,
        type: _type,
        description: _description,
        amount: amount,
        date: _date,
        category: _categories
            .firstWhere(
              (c) => c.id == _category,
              orElse: () => _categories.last,
            )
            .label,
      ),
    );
    Navigator.of(context).pop();
  }

  String _categoryIdFromLabel(String label) {
    final match = _categories.firstWhere(
      (category) => category.label.toLowerCase() == label.toLowerCase(),
      orElse: () => _categories.last,
    );
    return match.id;
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _TypeOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = isSelected
        ? option.color.withValues(alpha: 0.2)
        : const Color(0xFF1A1A1A);
    final borderColor = isSelected ? option.color : Colors.transparent;
    final textColor = isSelected ? option.color : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          children: [
            Icon(option.icon, size: 22, color: textColor),
            const SizedBox(height: 6),
            Text(
              option.label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeOption {
  const _TypeOption({
    required this.type,
    required this.label,
    required this.icon,
    required this.color,
  });

  final TransactionType type;
  final String label;
  final IconData icon;
  final Color color;
}

class _CategoryOption {
  const _CategoryOption({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

class TransactionFormData {
  const TransactionFormData({
    this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
  });

  final int? id;
  final TransactionType type;
  final String description;
  final double amount;
  final DateTime date;
  final String category;
}

const List<_TypeOption> _typeOptions = [
  _TypeOption(
    type: TransactionType.income,
    label: 'Income',
    icon: Icons.trending_up,
    color: AppColors.primary,
  ),
  _TypeOption(
    type: TransactionType.expense,
    label: 'Expense',
    icon: Icons.trending_down,
    color: AppColors.expense,
  ),
  _TypeOption(
    type: TransactionType.savings,
    label: 'Savings',
    icon: Icons.savings,
    color: AppColors.savings,
  ),
  _TypeOption(
    type: TransactionType.savingDeduct,
    label: 'Deduct',
    icon: Icons.money_off,
    color: Colors.orange,
  ),
];

const List<_CategoryOption> _categories = [
  _CategoryOption(id: 'salary', label: 'Salary', icon: Icons.work),
  _CategoryOption(
    id: 'freelance',
    label: 'Freelance',
    icon: Icons.phone_android,
  ),
  _CategoryOption(id: 'housing', label: 'Housing', icon: Icons.home),
  _CategoryOption(id: 'food', label: 'Food', icon: Icons.restaurant),
  _CategoryOption(id: 'shopping', label: 'Shopping', icon: Icons.shopping_cart),
  _CategoryOption(
    id: 'transport',
    label: 'Transport',
    icon: Icons.directions_car,
  ),
  _CategoryOption(id: 'health', label: 'Health', icon: Icons.favorite),
  _CategoryOption(id: 'education', label: 'Education', icon: Icons.school),
  _CategoryOption(id: 'travel', label: 'Travel', icon: Icons.flight),
  _CategoryOption(id: 'gifts', label: 'Gifts', icon: Icons.card_giftcard),
  _CategoryOption(id: 'utilities', label: 'Utilities', icon: Icons.bolt),
  _CategoryOption(id: 'other', label: 'Other', icon: Icons.sell),
];
