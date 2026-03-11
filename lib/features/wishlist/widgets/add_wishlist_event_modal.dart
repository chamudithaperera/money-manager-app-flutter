import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/theme.dart';

class AddWishlistEventModal extends StatefulWidget {
  const AddWishlistEventModal({
    super.key,
    required this.onSubmit,
    this.initialName,
  });

  final ValueChanged<String> onSubmit;
  final String? initialName;

  @override
  State<AddWishlistEventModal> createState() => _AddWishlistEventModalState();
}

class _AddWishlistEventModalState extends State<AddWishlistEventModal> {
  late final TextEditingController _nameController;
  String _name = '';

  @override
  void initState() {
    super.initState();
    _name = widget.initialName?.trim() ?? '';
    _nameController = TextEditingController(text: _name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialName != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.modalBackground,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.modalTop),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
                      isEditing ? 'Edit Event' : 'Add Event',
                      style: AppTextStyles.modalTitle,
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Symbols.close),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Event Name',
                  style: AppTextStyles.formLabel.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  onChanged: (value) => setState(() => _name = value),
                  style: AppTextStyles.inputText,
                  decoration: const InputDecoration(
                    hintText: 'e.g., April Trip',
                    prefixIcon: Icon(
                      Symbols.event,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _name.trim().isEmpty ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.large),
                      ),
                    ),
                    child: Text(
                      isEditing ? 'Update Event' : 'Create Event',
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

  void _submit() {
    widget.onSubmit(_name.trim());
    Navigator.of(context).pop();
  }
}
