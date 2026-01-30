import '../models/transaction.dart';

class HomeStats {
  const HomeStats({
    required this.balance,
    required this.income,
    required this.expenses,
    required this.savings,
  });

  final double balance;
  final double income;
  final double expenses;
  final double savings;
}

const HomeStats stats = HomeStats(
  balance: 12450.00,
  income: 5200.00,
  expenses: 2340.00,
  savings: 1500.00,
);

final List<Transaction> transactions = [
  Transaction(
    id: '1',
    title: 'Salary Deposit',
    category: 'Salary',
    type: TransactionType.income,
    amount: 4500.00,
    date: DateTime(2026, 1, 15),
  ),
  Transaction(
    id: '2',
    title: 'Rent Payment',
    category: 'Housing',
    type: TransactionType.expense,
    amount: 1200.00,
    date: DateTime(2026, 1, 14),
  ),
  Transaction(
    id: '3',
    title: 'Savings Transfer',
    category: 'Investments',
    type: TransactionType.savings,
    amount: 500.00,
    date: DateTime(2026, 1, 13),
  ),
  Transaction(
    id: '4',
    title: 'Grocery Shopping',
    category: 'Food',
    type: TransactionType.expense,
    amount: 156.80,
    date: DateTime(2026, 1, 12),
  ),
  Transaction(
    id: '5',
    title: 'Freelance Payment',
    category: 'Freelance',
    type: TransactionType.income,
    amount: 700.00,
    date: DateTime(2026, 1, 10),
  ),
];
