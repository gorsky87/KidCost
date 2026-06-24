import 'package:flutter/material.dart';

import '../../theme/kidcost_theme.dart';
import 'expense_models.dart';

extension ExpenseCategoryVisuals on ExpenseCategory {
  IconData get icon {
    switch (id) {
      case 'food':
        return Icons.restaurant_outlined;
      case 'clothes':
        return Icons.checkroom_outlined;
      case 'school':
        return Icons.school_outlined;
      case 'health':
        return Icons.medical_services_outlined;
      case 'activities':
        return Icons.sports_soccer_outlined;
      case 'holiday':
        return Icons.beach_access_outlined;
      case 'transport':
        return Icons.directions_car_outlined;
      case 'other':
        return Icons.more_horiz;
      default:
        return Icons.category_outlined;
    }
  }

  Color get accentColor {
    switch (id) {
      case 'food':
        return KidCostTheme.secondary;
      case 'clothes':
        return const Color(0xFF7C5CBA);
      case 'school':
        return KidCostTheme.tertiary;
      case 'health':
        return KidCostTheme.danger;
      case 'activities':
        return const Color(0xFF8A6F1E);
      case 'holiday':
        return const Color(0xFF2F7C95);
      case 'transport':
        return const Color(0xFF4F5D75);
      case 'other':
        return const Color(0xFF6F7D80);
      default:
        return KidCostTheme.primary;
    }
  }

  String get iconAssetPath {
    switch (id) {
      case 'food':
        return 'docs/icons/expense-categories/food.svg';
      case 'clothes':
        return 'docs/icons/expense-categories/clothes.svg';
      case 'school':
        return 'docs/icons/expense-categories/school.svg';
      case 'health':
        return 'docs/icons/expense-categories/health.svg';
      case 'activities':
        return 'docs/icons/expense-categories/activities.svg';
      case 'holiday':
        return 'docs/icons/expense-categories/holiday.svg';
      case 'transport':
        return 'docs/icons/expense-categories/transport.svg';
      case 'other':
        return 'docs/icons/expense-categories/other.svg';
      default:
        return 'docs/icons/expense-categories/other.svg';
    }
  }
}

extension ExpenseStatusVisuals on ExpenseStatus {
  IconData get icon {
    switch (this) {
      case ExpenseStatus.pending:
        return Icons.hourglass_top_outlined;
      case ExpenseStatus.accepted:
        return Icons.check_circle_outline;
      case ExpenseStatus.disputed:
        return Icons.report_problem_outlined;
      case ExpenseStatus.settled:
        return Icons.task_alt_outlined;
    }
  }

  Color get accentColor {
    switch (this) {
      case ExpenseStatus.pending:
        return KidCostTheme.warning;
      case ExpenseStatus.accepted:
        return KidCostTheme.success;
      case ExpenseStatus.disputed:
        return KidCostTheme.danger;
      case ExpenseStatus.settled:
        return KidCostTheme.primary;
    }
  }

  String get iconAssetPath {
    switch (this) {
      case ExpenseStatus.pending:
        return 'docs/icons/expense-statuses/pending.svg';
      case ExpenseStatus.accepted:
        return 'docs/icons/expense-statuses/accepted.svg';
      case ExpenseStatus.disputed:
        return 'docs/icons/expense-statuses/disputed.svg';
      case ExpenseStatus.settled:
        return 'docs/icons/expense-statuses/settled.svg';
    }
  }
}
