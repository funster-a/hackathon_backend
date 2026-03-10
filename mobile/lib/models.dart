import 'dart:ui';

class StartupPlanData {
  final double totalBudget;
  final double monthlyBurnRate;
  final int runwayMonths;
  final String advice;
  final List<CostCategory> categories;
  final List<TeamMember> team;

  StartupPlanData({
    required this.totalBudget,
    required this.monthlyBurnRate,
    required this.runwayMonths,
    required this.advice,
    required this.categories,
    required this.team,
  });

  factory StartupPlanData.fromJson(Map<String, dynamic> json) {
    return StartupPlanData(
      totalBudget: _parseDouble(json['total_budget']),
      monthlyBurnRate: _parseDouble(json['monthly_burn_rate']),
      runwayMonths: json['runway_months'] ?? 0,
      advice: json['advice']?.toString() ?? 'Совет не сгенерирован',
      categories: (json['categories'] is List)
          ? (json['categories'] as List)
                .map((c) => CostCategory.fromJson(c))
                .toList()
          : [],
      team: (json['team'] is List)
          ? (json['team'] as List).map((t) => TeamMember.fromJson(t)).toList()
          : [],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    }
    return 0.0;
  }
}

class CostCategory {
  final String name;
  final double amount;
  final double percent;
  final Color color;

  CostCategory({
    required this.name,
    required this.amount,
    required this.percent,
    required this.color,
  });

  factory CostCategory.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return CostCategory(
        name: "Ошибка",
        amount: 0,
        percent: 0,
        color: const Color(0xFFCCCCCC),
      );
    }

    return CostCategory(
      name: json['name']?.toString() ?? 'Без названия',
      amount: StartupPlanData._parseDouble(json['amount']),
      percent: StartupPlanData._parseDouble(json['percent']),
      color: _parseColor(json['color']),
    );
  }

  static Color _parseColor(dynamic hexString) {
    if (hexString == null) return const Color(0xFF9E9E9E);
    try {
      String hex = hexString.toString().trim();
      hex = hex.replaceAll('#', '').replaceAll('0x', '').replaceAll('0X', '');
      if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
      if (hex.length == 8) return Color(int.parse(hex, radix: 16));
      return const Color(0xFF9E9E9E);
    } catch (e) {
      return const Color(0xFF9E9E9E);
    }
  }
}

class TeamMember {
  final String role;
  final String stack;
  final double salary;

  TeamMember({required this.role, required this.stack, required this.salary});

  factory TeamMember.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return TeamMember(role: "Неизвестно", stack: "", salary: 0);
    }

    return TeamMember(
      role: json['role']?.toString() ?? 'Роль',
      stack: json['stack']?.toString() ?? 'Технологии',
      salary: StartupPlanData._parseDouble(json['salary']),
    );
  }
}
