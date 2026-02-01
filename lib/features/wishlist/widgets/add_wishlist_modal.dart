import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme.dart';
import '../../../providers/settings_provider.dart';
import '../models/wishlist_item.dart';

class AddWishlistModal extends ConsumerStatefulWidget {
  const AddWishlistModal({super.key, required this.onSubmit, this.initial});

  final ValueChanged<WishlistFormData> onSubmit;
  final WishlistItem? initial;

  @override
  ConsumerState<AddWishlistModal> createState() => _AddWishlistModalState();
}

class _AddWishlistModalState extends ConsumerState<AddWishlistModal> {
  String _name = '';
  String _description = '';
  String _estimatedPrice = '';
  DateTime _estimatedDate = DateTime.now();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _name = initial.name;
      _description = initial.description;
      _estimatedPrice = initial.estimatedPrice.toStringAsFixed(2);
      _estimatedDate = initial.estimatedDate;
    }
    _nameController = TextEditingController(text: _name);
    _descriptionController = TextEditingController(text: _description);
    _priceController = TextEditingController(text: _estimatedPrice);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        ref.watch(settingsProvider).asData?.value.currencySymbol ??
        AppConstants.currencySymbol;

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
                      isEditing ? 'Edit Item' : 'Add Item',
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
                _sectionLabel('Item Name'),
                const SizedBox(height: 8),
                _textField(
                  hint: 'e.g., New Laptop',
                  icon: Icons.label_outline,
                  controller: _nameController,
                  onChanged: (value) => setState(() => _name = value),
                ),
                const SizedBox(height: 16),
                _sectionLabel('Description'),
                const SizedBox(height: 8),
                _textField(
                  hint: 'Details about the item',
                  icon: Icons.description_outlined,
                  controller: _descriptionController,
                  onChanged: (value) => setState(() => _description = value),
                ),
                const SizedBox(height: 16),
                _sectionLabel('Estimated Price'),
                const SizedBox(height: 8),
                _textField(
                  hint: '0.00',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  prefixText: '$currency ',
                  controller: _priceController,
                  onChanged: (value) => setState(() => _estimatedPrice = value),
                ),
                const SizedBox(height: 16),
                _sectionLabel('Estimated Date'),
                const SizedBox(height: 8),
                _dateField(),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _name.isEmpty || _estimatedPrice.isEmpty
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
                      isEditing ? 'Update Item' : 'Add Item',
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
        '${_estimatedDate.month.toString().padLeft(2, '0')}/${_estimatedDate.day.toString().padLeft(2, '0')}/${_estimatedDate.year}';
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

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _estimatedDate,
      firstDate: DateTime.now(),
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
      setState(() => _estimatedDate = picked);
    }
  }

  void _submit() {
    final price = double.tryParse(_estimatedPrice) ?? 0;
    widget.onSubmit(
      WishlistFormData(
        id: widget.initial?.id,
        name: _name,
        description: _description,
        estimatedPrice: price,
        estimatedDate: _estimatedDate,
      ),
    );
    Navigator.of(context).pop();
  }
}

class WishlistFormData {
  const WishlistFormData({
    this.id,
    required this.name,
    required this.description,
    required this.estimatedPrice,
    required this.estimatedDate,
  });

  final String? id;
  final String name;
  final String description;
  final double estimatedPrice;
  final DateTime estimatedDate;
}
