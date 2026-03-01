import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme.dart';
import '../../../providers/settings_provider.dart';
import '../models/wallet.dart';
import '../models/wallet_transfer.dart';
import '../providers/wallet_transfer_provider.dart';
import '../providers/wallet_provider.dart';

class TransferMoneyModal extends ConsumerStatefulWidget {
  const TransferMoneyModal({super.key});

  @override
  ConsumerState<TransferMoneyModal> createState() => _TransferMoneyModalState();
}

class _TransferMoneyModalState extends ConsumerState<TransferMoneyModal> {
  int? _fromWalletId;
  int? _toWalletId;
  String _amount = '';
  String _note = '';
  DateTime _date = DateTime.now();

  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletsProvider).value ?? const <Wallet>[];
    final availableWallets = wallets
        .where((wallet) => wallet.id != null)
        .toList();

    final fromWalletId = _resolveFromWalletId(availableWallets);
    final toWalletId = _resolveToWalletId(availableWallets, fromWalletId);
    final currency =
        ref.watch(settingsProvider).asData?.value.currencySymbol ??
        AppConstants.currencySymbol;

    final canSubmit =
        availableWallets.length >= 2 &&
        fromWalletId != null &&
        toWalletId != null &&
        fromWalletId != toWalletId &&
        _amount.trim().isNotEmpty;

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
                    Text('Transfer Money', style: AppTextStyles.modalTitle),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Symbols.close),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (availableWallets.length < 2)
                  Text(
                    'Create at least two wallets to make transfers.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  )
                else ...[
                  _sectionLabel('From Wallet'),
                  const SizedBox(height: 8),
                  _walletSelector(
                    wallets: availableWallets,
                    selectedId: fromWalletId,
                    onChanged: (value) => setState(() {
                      _fromWalletId = value;
                      if (_toWalletId == value) {
                        _toWalletId = _firstOtherWalletId(
                          wallets: availableWallets,
                          currentId: value,
                        );
                      }
                    }),
                  ),
                  const SizedBox(height: 14),
                  _sectionLabel('To Wallet'),
                  const SizedBox(height: 8),
                  _walletSelector(
                    wallets: availableWallets,
                    selectedId: toWalletId,
                    onChanged: (value) => setState(() => _toWalletId = value),
                  ),
                  const SizedBox(height: 14),
                  _sectionLabel('Amount'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (value) => setState(() => _amount = value),
                    style: AppTextStyles.inputText,
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixText: '$currency ',
                      prefixIcon: const Icon(
                        Symbols.attach_money,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sectionLabel('Date'),
                  const SizedBox(height: 8),
                  _dateField(),
                  const SizedBox(height: 14),
                  _sectionLabel('Note (Optional)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    onChanged: (value) => setState(() => _note = value),
                    style: AppTextStyles.inputText,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Move money to savings wallet',
                      prefixIcon: Icon(
                        Symbols.description,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canSubmit
                        ? () => _submit(
                            fromWalletId: fromWalletId,
                            toWalletId: toWalletId,
                          )
                        : null,
                    child: const Text('Transfer'),
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

  Widget _walletSelector({
    required List<Wallet> wallets,
    required int? selectedId,
    required ValueChanged<int> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: selectedId,
      dropdownColor: AppColors.surface,
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Symbols.account_balance_wallet,
          size: 18,
          color: AppColors.textTertiary,
        ),
        hintText: 'Select wallet',
      ),
      items: wallets
          .map(
            (wallet) => DropdownMenuItem<int>(
              value: wallet.id!,
              child: Text(
                wallet.isDefault ? '${wallet.name} (Default)' : wallet.name,
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        onChanged(value);
      },
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
              Symbols.calendar_month,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }

  int? _resolveFromWalletId(List<Wallet> wallets) {
    if (_fromWalletId != null &&
        wallets.any((wallet) => wallet.id == _fromWalletId)) {
      return _fromWalletId;
    }

    final defaultWallet = wallets.where((wallet) => wallet.isDefault);
    if (defaultWallet.isNotEmpty) {
      return defaultWallet.first.id;
    }

    return wallets.isEmpty ? null : wallets.first.id;
  }

  int? _resolveToWalletId(List<Wallet> wallets, int? fromWalletId) {
    if (_toWalletId != null &&
        wallets.any((wallet) => wallet.id == _toWalletId)) {
      return _toWalletId;
    }

    for (final wallet in wallets) {
      if (wallet.id != fromWalletId) {
        return wallet.id;
      }
    }

    return null;
  }

  int? _firstOtherWalletId({
    required List<Wallet> wallets,
    required int currentId,
  }) {
    for (final wallet in wallets) {
      if (wallet.id != currentId) {
        return wallet.id;
      }
    }
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _submit({
    required int fromWalletId,
    required int toWalletId,
  }) async {
    final amount = double.tryParse(_amount.trim());
    if (amount == null || amount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid transfer amount.')),
      );
      return;
    }

    if (fromWalletId == toWalletId) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Source and destination wallets cannot be the same.'),
        ),
      );
      return;
    }

    try {
      await ref
          .read(walletTransfersProvider.notifier)
          .createTransfer(
            WalletTransfer(
              fromWalletId: fromWalletId,
              toWalletId: toWalletId,
              amount: amount,
              note: _note.trim().isEmpty ? null : _note.trim(),
              date: _date,
            ),
          );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to transfer money: $error')),
      );
    }
  }
}
