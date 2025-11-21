import 'dart:ui';

class FinanceData {
  final double totalSpent;
  final double forecast;
  final String advice;
  final List<CategoryItem> categories;
  final List<SubscriptionItem> subscriptions;

  FinanceData({
    required this.totalSpent,
    required this.forecast,
    required this.advice,
    required this.categories,
    required this.subscriptions,
  });

  factory FinanceData.fromJson(Map<String, dynamic> json) {
    return FinanceData(
      // Safe parsing for numbers: handle int, double, and String
      totalSpent: _parseDouble(json['total_spent']),
      forecast: _parseDouble(json['forecast_next_month'] ?? json['forecast']), // AI sometimes messes up keys
      advice: json['advice']?.toString() ?? 'Совет не сгенерирован',
      
      // Safe parsing for lists: check if it is actually a List
      categories: (json['categories'] is List)
          ? (json['categories'] as List)
              .map((e) => CategoryItem.fromJson(e))
              .toList()
          : [], // If not a list, return empty to avoid crash
      
      subscriptions: (json['subscriptions'] is List)
          ? (json['subscriptions'] as List)
              .map((e) => SubscriptionItem.fromJson(e))
              .toList()
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

class CategoryItem {
  final String name;
  final double amount;
  final double percent;
  final Color color;

  CategoryItem({required this.name, required this.amount, required this.percent, required this.color});

  factory CategoryItem.fromJson(dynamic json) {
    // If json is not a Map (AI sometimes sends strings), return a dummy
    if (json is! Map<String, dynamic>) {
      return CategoryItem(name: "Ошибка", amount: 0, percent: 0, color: const Color(0xFFCCCCCC));
    }

    return CategoryItem(
      name: json['name']?.toString() ?? 'Без названия',
      amount: FinanceData._parseDouble(json['amount']),
      percent: FinanceData._parseDouble(json['percent']),
      color: _parseColor(json['color']),
    );
  }

  static Color _parseColor(dynamic hexString) {
    if (hexString == null) return const Color(0xFF9E9E9E);
    try {
      final buffer = StringBuffer();
      String hex = hexString.toString().replaceAll('#', '');
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex);
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return const Color(0xFF9E9E9E);
    }
  }
}

class SubscriptionItem {
  final String name;
  final double cost;

  SubscriptionItem({required this.name, required this.cost});

  factory SubscriptionItem.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return SubscriptionItem(name: "Unknown", cost: 0);
    }
    return SubscriptionItem(
      name: json['name']?.toString() ?? 'Сервис',
      cost: FinanceData._parseDouble(json['cost']),
    );
  }
}