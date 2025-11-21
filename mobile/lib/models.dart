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
      totalSpent: (json['total_spent'] as num).toDouble(),
      forecast: (json['forecast_next_month'] as num).toDouble(),
      advice: json['advice'] ?? '',
      categories: (json['categories'] as List)
          .map((e) => CategoryItem.fromJson(e))
          .toList(),
      subscriptions: (json['subscriptions'] as List)
          .map((e) => SubscriptionItem.fromJson(e))
          .toList(),
    );
  }
}

class CategoryItem {
  final String name;
  final double amount;
  final double percent;
  final Color color;

  CategoryItem({required this.name, required this.amount, required this.percent, required this.color});

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      name: json['name'],
      amount: (json['amount'] as num).toDouble(),
      percent: (json['percent'] as num).toDouble(),
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

  factory SubscriptionItem.fromJson(Map<String, dynamic> json) {
    return SubscriptionItem(
      name: json['name'],
      cost: (json['cost'] as num).toDouble(),
    );
  }
}