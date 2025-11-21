import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'localization.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final TextEditingController _goalController = TextEditingController();
  String? _selectedIncomeKey; // Храним ключ, а не локализованную строку
  bool _isLoading = false;

  // Ключи для вариантов ежемесячного дохода (для локализации)
  final List<String> _incomeOptionKeys = [
    'goals_income_option1',
    'goals_income_option2',
    'goals_income_option3',
    'goals_income_option4',
    'goals_income_option5',
    'goals_income_option6',
  ];
  
  // Получить локализованные варианты дохода
  List<String> get _incomeOptions {
    return _incomeOptionKeys.map((key) => AppStrings.get(key)).toList();
  }
  
  // Получить текущее выбранное значение для dropdown
  String? get _selectedIncomeValue {
    if (_selectedIncomeKey == null) return null;
    return AppStrings.get(_selectedIncomeKey!);
  }

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIncomeKey = prefs.getString('user_income_key');
    setState(() {
      _goalController.text = prefs.getString('user_goal') ?? '';
      // Восстанавливаем выбранный доход по ключу (для локализации)
      if (savedIncomeKey != null && _incomeOptionKeys.contains(savedIncomeKey)) {
        _selectedIncomeKey = savedIncomeKey;
      }
    });
  }

  Future<void> _saveData() async {
    if (_goalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.get('goals_error_empty')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      // 💾 СОХРАНЕНИЕ: Сохраняем финансовую цель в SharedPreferences
      // Ключ: 'user_goal'
      // Используется в: api_service.dart -> sendChatMessage() -> отправляется на бэкенд
      await prefs.setString('user_goal', _goalController.text.trim());
      if (_selectedIncomeKey != null) {
        // Сохраняем ключ для локализации
        await prefs.setString('user_income_key', _selectedIncomeKey!);
        // Сохраняем и локализованную строку для совместимости
        await prefs.setString('user_income', AppStrings.get(_selectedIncomeKey!));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get('goals_saved')),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get('goals_error_save')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Language>(
      valueListenable: AppStrings.languageNotifier,
      builder: (context, language, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : Colors.black87;
        final subTextColor = isDark ? Colors.white70 : Colors.grey[600];

        return Scaffold(
          appBar: AppBar(
            title: Text(
              AppStrings.get('goals_title'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            elevation: 0,
            automaticallyImplyLeading: false, // Убираем кнопку назад для работы в табах
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Иконка и описание
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E3A59).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.flag,
                          size: 48,
                          color: Color(0xFF2E3A59),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.get('goals_subtitle'),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: subTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Поле ввода финансовой цели
                Text(
                  AppStrings.get('goals_goal_label'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _goalController,
                  maxLines: 3,
                  minLines: 1,
                  style: TextStyle(color: textColor),
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  textCapitalization: TextCapitalization.sentences,
                  enableInteractiveSelection: true,
                  enableSuggestions: true,
                  autocorrect: true,
                  decoration: InputDecoration(
                    hintText: AppStrings.get('goals_goal_hint'),
                    hintStyle: TextStyle(color: subTextColor),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 30),

                // Выпадающий список дохода
                Text(
                  AppStrings.get('goals_income_label'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedIncomeValue,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                    dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    style: TextStyle(color: textColor),
                    hint: Text(
                      AppStrings.get('goals_income_hint'),
                      style: TextStyle(color: subTextColor),
                    ),
                    items: _incomeOptions.map((income) {
                      return DropdownMenuItem<String>(
                        value: income,
                        child: Text(income),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        // Находим ключ по локализованному значению
                        final index = _incomeOptions.indexOf(value!);
                        if (index >= 0 && index < _incomeOptionKeys.length) {
                          _selectedIncomeKey = _incomeOptionKeys[index];
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(height: 40),

                // Кнопка сохранения
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E3A59),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            AppStrings.get('goals_save_button'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

