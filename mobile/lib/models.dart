import 'dart:ui';

class FinanceData {
  final double totalSpent;
  final double forecast;
  final String advice;
  final List<CategoryItem> categories;
  final List<SubscriptionItem> subscriptions;
  final List<TransactionItem> transactions;

  FinanceData({
    required this.totalSpent,
    required this.forecast,
    required this.advice,
    required this.categories,
    required this.subscriptions,
    required this.transactions,
  });

  factory FinanceData.fromJson(Map<String, dynamic> json) {
    return FinanceData(
      // Safe parsing for numbers: handle int, double, and String
      totalSpent: _parseDouble(json['total_spent']),
      forecast: _parseDouble(json['forecast_next_month'] ?? json['forecast']), // AI sometimes messes up keys
      advice: json['advice']?.toString() ?? 'Совет не сгенерирован',
      // TODO: localize advice
      
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
      
      transactions: (json['transactions'] is List)
          ? (json['transactions'] as List)
              .map((e) => TransactionItem.fromJson(e))
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
  final String? nameRu;
  final String? nameKz;
  final String? nameEn;

  CategoryItem({
    required this.name,
    required this.amount,
    required this.percent,
    required this.color,
    this.nameRu,
    this.nameKz,
    this.nameEn,
  });
  
  // Получить название на текущем языке
  String getLocalizedName() {
    // Импортируем AppStrings для получения текущего языка
    // Но так как это модель, лучше передавать язык извне
    return name; // По умолчанию возвращаем name
  }
  
  String getNameForLanguage(String langCode) {
    switch (langCode) {
      case 'ru':
        return nameRu ?? name;
      case 'kz':
        return nameKz ?? name;
      case 'en':
        return nameEn ?? name;
      default:
        return name;
    }
  }

  factory CategoryItem.fromJson(dynamic json) {
    // If json is not a Map (AI sometimes sends strings), return a dummy
    if (json is! Map<String, dynamic>) {
      return CategoryItem(name: "Ошибка", amount: 0, percent: 0, color: const Color(0xFFCCCCCC));
    }

    return CategoryItem(
      name: json['name']?.toString() ?? 'Без названия',
      nameRu: json['name_ru']?.toString(),
      nameKz: json['name_kz']?.toString(),
      nameEn: json['name_en']?.toString(),
      amount: FinanceData._parseDouble(json['amount']),
      percent: FinanceData._parseDouble(json['percent']),
      color: _parseColor(json['color']),
    );
  }

  static Color _parseColor(dynamic hexString) {
    if (hexString == null) return const Color(0xFF9E9E9E);
    try {
      String hex = hexString.toString().trim();
      
      // Убираем все префиксы (#, 0x, 0X)
      hex = hex.replaceAll('#', '').replaceAll('0x', '').replaceAll('0X', '');
      
      // Если длина 6 символов (RGB), добавляем альфа-канал FF
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
      
      // Если длина 8 символов (ARGB), используем как есть
      if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
      
      // Если ничего не подошло, возвращаем серый
      return const Color(0xFF9E9E9E);
    } catch (e) {
      print('Error parsing color: $hexString, error: $e');
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

class TransactionItem {
  final DateTime date;
  final double amount;
  final String name; // description из JSON
  final String category;

  TransactionItem({
    required this.date,
    required this.amount,
    required this.name,
    required this.category,
  });

  factory TransactionItem.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return TransactionItem(
        date: DateTime.now(),
        amount: 0,
        name: "Неизвестная транзакция",
        category: "Прочее",
      );
    }

    return TransactionItem(
      date: _parseDate(json['date']),
      amount: FinanceData._parseDouble(json['amount']),
      name: json['description']?.toString() ?? json['name']?.toString() ?? 'Без описания',
      category: json['category']?.toString() ?? 'Прочее',
    );
  }

  static DateTime _parseDate(dynamic dateString) {
    if (dateString == null) return DateTime.now();
    
    try {
      String dateStr = dateString.toString().trim();
      
      // Пробуем формат DD.MM.YYYY
      if (dateStr.contains('.')) {
        final parts = dateStr.split('.');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      }
      
      // Пробуем формат ISO YYYY-MM-DD
      if (dateStr.contains('-')) {
        return DateTime.parse(dateStr);
      }
      
      // Пробуем стандартный парсинг
      return DateTime.parse(dateStr);
    } catch (e) {
      print('Error parsing date: $dateString, error: $e');
      return DateTime.now();
    }
  }
}