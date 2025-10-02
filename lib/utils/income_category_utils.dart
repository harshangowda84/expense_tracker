import 'package:flutter/material.dart';
import '../models/income_transaction.dart';

class IncomeCategoryUtils {
  static String getCategoryName(IncomeCategory category) {
    switch (category) {
      case IncomeCategory.salary:
        return 'Salary';
      case IncomeCategory.freelance:
        return 'Freelance';
      case IncomeCategory.business:
        return 'Business';
      case IncomeCategory.investment:
        return 'Investment';
      case IncomeCategory.bonus:
        return 'Bonus';
      case IncomeCategory.refund:
        return 'Refund';
      case IncomeCategory.gift:
        return 'Gift';
      case IncomeCategory.other:
        return 'Other';
    }
  }

  static IconData getCategoryIcon(IncomeCategory category) {
    switch (category) {
      case IncomeCategory.salary:
        return Icons.work;
      case IncomeCategory.freelance:
        return Icons.laptop;
      case IncomeCategory.business:
        return Icons.business;
      case IncomeCategory.investment:
        return Icons.trending_up;
      case IncomeCategory.bonus:
        return Icons.card_giftcard;
      case IncomeCategory.refund:
        return Icons.money_off;
      case IncomeCategory.gift:
        return Icons.redeem;
      case IncomeCategory.other:
        return Icons.more_horiz;
    }
  }

  static Color getCategoryColor(IncomeCategory category) {
    switch (category) {
      case IncomeCategory.salary:
        return const Color(0xFF4CAF50); // Green
      case IncomeCategory.freelance:
        return const Color(0xFF2196F3); // Blue
      case IncomeCategory.business:
        return const Color(0xFF9C27B0); // Purple
      case IncomeCategory.investment:
        return const Color(0xFF00BCD4); // Cyan
      case IncomeCategory.bonus:
        return const Color(0xFFFF9800); // Orange
      case IncomeCategory.refund:
        return const Color(0xFF795548); // Brown
      case IncomeCategory.gift:
        return const Color(0xFFE91E63); // Pink
      case IncomeCategory.other:
        return const Color(0xFF607D8B); // Blue Grey
    }
  }

  static List<IncomeCategory> getAllCategories() {
    return IncomeCategory.values;
  }
}