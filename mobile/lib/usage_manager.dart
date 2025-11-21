import 'package:shared_preferences/shared_preferences.dart';

class UsageManager {
  static const String _keyUsageCount = 'usage_count';
  static const String _keyIsPremium = 'is_premium';
  static const int _maxFreeActions = 5;

  // Singleton pattern
  static final UsageManager _instance = UsageManager._internal();
  factory UsageManager() => _instance;
  UsageManager._internal();

  // Кэш для SharedPreferences
  SharedPreferences? _prefs;
  
  // In-memory fallback для случаев, когда SharedPreferences недоступен
  bool _inMemoryPremium = false;
  int _inMemoryUsageCount = 0;
  
  // Получение SharedPreferences с кэшированием
  Future<SharedPreferences?> _getPrefs() async {
    if (_prefs != null) return _prefs;
    try {
      _prefs = await SharedPreferences.getInstance();
      return _prefs;
    } catch (e) {
      print('Error getting SharedPreferences: $e');
      return null;
    }
  }

  // Проверяет, может ли пользователь выполнить действие
  Future<bool> canAction() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) {
        // Используем in-memory fallback
        if (_inMemoryPremium) return true;
        return _inMemoryUsageCount < _maxFreeActions;
      }
      
      final isPremium = prefs.getBool(_keyIsPremium) ?? _inMemoryPremium;
      
      // Если премиум - безлимит
      if (isPremium) return true;
      
      // Проверяем лимит для бесплатной версии
      final usageCount = prefs.getInt(_keyUsageCount) ?? _inMemoryUsageCount;
      return usageCount < _maxFreeActions;
    } catch (e) {
      // В случае ошибки используем in-memory fallback
      print('Error in canAction: $e');
      if (_inMemoryPremium) return true;
      return _inMemoryUsageCount < _maxFreeActions;
    }
  }

  // Увеличивает счетчик использований
  Future<void> incrementUsage() async {
    try {
      final prefs = await _getPrefs();
      
      // Проверяем премиум статус
      bool isPremium = false;
      if (prefs != null) {
        isPremium = prefs.getBool(_keyIsPremium) ?? false;
      } else {
        isPremium = _inMemoryPremium;
      }
      
      // Не увеличиваем счетчик для премиум пользователей
      if (isPremium) return;
      
      if (prefs != null) {
        final currentCount = prefs.getInt(_keyUsageCount) ?? 0;
        await prefs.setInt(_keyUsageCount, currentCount + 1);
        _inMemoryUsageCount = currentCount + 1; // Обновляем кэш
      } else {
        // Используем in-memory fallback
        _inMemoryUsageCount++;
      }
    } catch (e) {
      // В случае ошибки используем in-memory fallback
      print('Error in incrementUsage: $e');
      if (!_inMemoryPremium) {
        _inMemoryUsageCount++;
      }
    }
  }

  // Включает премиум режим
  Future<void> setPremium() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) {
        print('Warning: Unable to access SharedPreferences, using in-memory storage');
        // Используем in-memory fallback
        _inMemoryPremium = true;
        return;
      }
      await prefs.setBool(_keyIsPremium, true);
      _inMemoryPremium = true; // Обновляем кэш
    } catch (e) {
      // В случае ошибки используем in-memory fallback
      print('Error in setPremium: $e, using in-memory storage');
      _inMemoryPremium = true;
    }
  }

  // Получает количество оставшихся попыток
  Future<int> get remainingAttempts async {
    try {
      final prefs = await _getPrefs();
      
      bool isPremium = false;
      int usageCount = 0;
      
      if (prefs != null) {
        isPremium = prefs.getBool(_keyIsPremium) ?? _inMemoryPremium;
        usageCount = prefs.getInt(_keyUsageCount) ?? _inMemoryUsageCount;
      } else {
        isPremium = _inMemoryPremium;
        usageCount = _inMemoryUsageCount;
      }
      
      // Премиум пользователи имеют безлимит
      if (isPremium) return -1; // -1 означает безлимит
      
      final remaining = _maxFreeActions - usageCount;
      return remaining > 0 ? remaining : 0;
    } catch (e) {
      // В случае ошибки используем in-memory fallback
      print('Error in remainingAttempts: $e');
      if (_inMemoryPremium) return -1;
      final remaining = _maxFreeActions - _inMemoryUsageCount;
      return remaining > 0 ? remaining : 0;
    }
  }

  // Получает текущий счетчик использований
  Future<int> get usageCount async {
    try {
      final prefs = await _getPrefs();
      if (prefs != null) {
        final count = prefs.getInt(_keyUsageCount);
        if (count != null) {
          _inMemoryUsageCount = count; // Обновляем кэш
          return count;
        }
      }
      return _inMemoryUsageCount;
    } catch (e) {
      print('Error in usageCount: $e');
      return _inMemoryUsageCount;
    }
  }

  // Проверяет, является ли пользователь премиум
  Future<bool> get isPremium async {
    try {
      final prefs = await _getPrefs();
      if (prefs != null) {
        final premium = prefs.getBool(_keyIsPremium);
        if (premium != null) {
          _inMemoryPremium = premium; // Обновляем кэш
          return premium;
        }
      }
      return _inMemoryPremium;
    } catch (e) {
      print('Error in isPremium: $e');
      return _inMemoryPremium;
    }
  }

  // Сброс данных (для тестирования)
  Future<void> reset() async {
    try {
      final prefs = await _getPrefs();
      if (prefs != null) {
        await prefs.remove(_keyUsageCount);
        await prefs.remove(_keyIsPremium);
      }
      // Сбрасываем in-memory данные
      _inMemoryPremium = false;
      _inMemoryUsageCount = 0;
      _prefs = null; // Сбрасываем кэш
    } catch (e) {
      print('Error in reset: $e');
      // Все равно сбрасываем in-memory данные
      _inMemoryPremium = false;
      _inMemoryUsageCount = 0;
    }
  }
}

