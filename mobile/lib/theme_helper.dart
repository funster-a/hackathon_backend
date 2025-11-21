import 'package:flutter/material.dart';

// Глобальный ключ для доступа к состоянию темы
// Будет инициализирован в main.dart
GlobalKey? _appStateKey;

void setAppStateKey(GlobalKey key) {
  _appStateKey = key;
}

GlobalKey? get appStateKey => _appStateKey;

// Функции-хелперы для переключения темы
void toggleTheme() {
  final state = _appStateKey?.currentState;
  if (state != null) {
    (state as dynamic).toggleTheme();
  }
}

IconData getThemeIcon() {
  final state = _appStateKey?.currentState;
  if (state != null) {
    return (state as dynamic).themeIcon ?? Icons.brightness_auto;
  }
  return Icons.brightness_auto;
}

