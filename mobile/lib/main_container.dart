import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'chat_screen.dart';
import 'goals_screen.dart';
import 'profile_screen.dart';
import 'pin_screen.dart';
import 'models.dart';
import 'localization.dart';

class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;
  bool _isCheckingPin = true;
  bool _pinSet = false;
  
  // Состояние для ChatScreen (нужно для передачи данных из FinanceScreen)
  FinanceData? _chatFinanceData;
  Map<String, dynamic>? _chatRawContext;
  final List<Map<String, String>> _chatHistory = [];

  @override
  void initState() {
    super.initState();
    _checkPinAndLoadData();
  }

  Future<void> _checkPinAndLoadData() async {
    // Проверяем, установлен ли PIN-код
    final pinSet = await PinScreen.isPinSet();
    
    if (mounted) {
      setState(() {
        _pinSet = pinSet;
        _isCheckingPin = false;
      });
      
      // Загружаем данные только если PIN проверен или не установлен
      if (!pinSet) {
        _loadSavedFinanceData();
      }
    }
  }

  // Загружаем сохраненные данные при инициализации
  Future<void> _loadSavedFinanceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('finance_data_json');
      
      if (savedJson != null) {
        final jsonData = json.decode(savedJson) as Map<String, dynamic>;
        final financeData = FinanceData.fromJson(jsonData);
        
        if (mounted) {
          setState(() {
            _chatFinanceData = financeData;
            _chatRawContext = jsonData;
            // Добавляем приветственное сообщение, если истории нет
            if (_chatHistory.isEmpty) {
              _chatHistory.add({
                "role": "ai", 
                "text": AppStrings.get('chat_welcome_message')
              });
            }
          });
        }
      }
    } catch (e) {
      print("Ошибка загрузки сохраненных данных: $e");
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Метод для открытия чата с данными из FinanceScreen
  void openChatWithData(FinanceData financeData, Map<String, dynamic> rawContext) {
    setState(() {
      _chatFinanceData = financeData;
      _chatRawContext = rawContext;
      _chatHistory.clear();
      _chatHistory.add({
        "role": "ai", 
        "text": AppStrings.get('chat_welcome_message')
      });
      _currentIndex = 1; // Переключаемся на вкладку чата
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Если проверяем PIN, показываем загрузку
    if (_isCheckingPin) {
      return const Scaffold(
        backgroundColor: Color(0xFF2E3A59),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }
    
    // Если PIN установлен, показываем экран ввода PIN
    if (_pinSet) {
      return PinScreen(
        mode: PinMode.verify,
        onSuccess: () {
          // После успешной проверки PIN загружаем данные и показываем контейнер
          setState(() {
            _pinSet = false;
          });
          _loadSavedFinanceData();
        },
      );
    }
    
    return Scaffold(
      extendBody: true, // Позволяет контенту проходить под панелью навигации
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Index 0: FinanceScreen (Главная)
          FinanceScreen(
            onChatRequested: openChatWithData,
          ),
          // Index 1: ChatScreen (Чат)
          _chatFinanceData != null && _chatRawContext != null
              ? ChatScreen(
                  financeData: _chatFinanceData!,
                  rawContext: _chatRawContext!,
                  messages: _chatHistory,
                )
              : _buildEmptyChatScreen(),
          // Index 2: GoalsScreen (Цели)
          const GoalsScreen(),
          // Index 3: ProfileScreen (Профиль)
          ProfileScreen(
            onLogout: () {
              // Очищаем данные при выходе
              setState(() {
                _chatFinanceData = null;
                _chatRawContext = null;
                _chatHistory.clear();
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: _buildLiquidGlassNavigation(isDark),
    );
  }

  Widget _buildEmptyChatScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: isDark ? Colors.white38 : Colors.grey[400],
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder<Language>(
              valueListenable: AppStrings.languageNotifier,
              builder: (context, language, child) {
                return Text(
                  AppStrings.get('chat_empty_message'),
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white70 : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiquidGlassNavigation(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ValueListenableBuilder<Language>(
              valueListenable: AppStrings.languageNotifier,
              builder: (context, language, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      icon: CupertinoIcons.chart_bar_alt_fill,
                      label: AppStrings.get('dashboard_title'),
                      index: 0,
                      isDark: isDark,
                    ),
                    _buildNavItem(
                      icon: CupertinoIcons.chat_bubble_2_fill,
                      label: AppStrings.get('chat_title'),
                      index: 1,
                      isDark: isDark,
                    ),
                    _buildNavItem(
                      icon: CupertinoIcons.flag_fill,
                      label: AppStrings.get('goals_title'),
                      index: 2,
                      isDark: isDark,
                    ),
                    _buildNavItem(
                      icon: CupertinoIcons.person_fill,
                      label: AppStrings.get('profile_title'),
                      index: 3,
                      isDark: isDark,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isDark,
  }) {
    final isActive = _currentIndex == index;
    final activeColor = Colors.amber;
    final inactiveColor = isDark
        ? Colors.white.withOpacity(0.5)
        : Colors.black.withOpacity(0.5);

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isActive
                      ? activeColor.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isActive ? activeColor : inactiveColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? activeColor : inactiveColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


