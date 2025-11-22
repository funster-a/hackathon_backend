import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'localization.dart';
import 'alert_helper.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final TextEditingController _goalController = TextEditingController();
  String? _selectedIncomeKey; // Храним ключ, а не локализованную строку
  bool _isLoading = false;
  List<Map<String, dynamic>> _savedGoals = []; // Список сохраненных целей с прогрессом
  Set<int> _expandedGoals = {}; // Индексы раскрытых карточек

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
    
    // Загружаем список сохраненных целей (старый формат - список строк)
    final savedGoalsList = prefs.getStringList('saved_goals_list') ?? [];
    
    // Конвертируем в новый формат с прогрессом
    final goalsWithProgress = savedGoalsList.map((goal) {
      // Пытаемся загрузить сохраненный прогресс для этой цели
      final savedProgress = prefs.getDouble('goal_progress_${goal.hashCode}') ?? 0.0;
      return {
        'text': goal,
        'progress': savedProgress,
      };
    }).toList();
    
    setState(() {
      _goalController.text = '';
      _savedGoals = goalsWithProgress;
      // Восстанавливаем выбранный доход по ключу (для локализации)
      if (savedIncomeKey != null && _incomeOptionKeys.contains(savedIncomeKey)) {
        _selectedIncomeKey = savedIncomeKey;
      }
    });
  }

  Future<void> _saveData() async {
    if (_goalController.text.trim().isEmpty) {
      showErrorAlert(
        context,
        message: AppStrings.get('goals_error_empty'),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final goalText = _goalController.text.trim();
      
      // Проверяем, нет ли уже такой цели
      final exists = _savedGoals.any((goal) => goal['text'] == goalText);
      if (exists) {
        showErrorAlert(
          context,
          message: 'Эта цель уже существует',
        );
        return;
      }
      
      // Добавляем новую цель в список с нулевым прогрессом
      final updatedGoals = List<Map<String, dynamic>>.from(_savedGoals);
      updatedGoals.add({
        'text': goalText,
        'progress': 0.0,
      });
      
      // Сохраняем список целей (старый формат для совместимости)
      final goalsTextList = updatedGoals.map((g) => g['text'] as String).toList();
      await prefs.setStringList('saved_goals_list', goalsTextList);
      
      // Также сохраняем последнюю цель как основную (для совместимости с API)
      await prefs.setString('user_goal', goalText);
      
      if (_selectedIncomeKey != null) {
        // Сохраняем ключ для локализации
        await prefs.setString('user_income_key', _selectedIncomeKey!);
        // Сохраняем и локализованную строку для совместимости
        await prefs.setString('user_income', AppStrings.get(_selectedIncomeKey!));
      }

      if (mounted) {
        setState(() {
          _savedGoals = updatedGoals;
          _goalController.clear();
        });
        showSuccessAlert(
          context,
          message: AppStrings.get('goals_saved'),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorAlert(
          context,
          message: AppStrings.get('goals_error_save'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildGoalCard(
    BuildContext context, {
    required String goalText,
    required double progress,
    required int index,
    required bool isDark,
    required Color textColor,
    required Color? subTextColor,
  }) {
    final safeSubTextColor = subTextColor ?? (isDark ? Colors.white70 : Colors.grey[600]!);
    final progressController = TextEditingController(
      text: progress.toStringAsFixed(0),
    );
    final isExpanded = _expandedGoals.contains(index);
    
    return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Компактная часть: название и прогресс-бар
              InkWell(
                onTap: () {
                  setState(() {
                    if (_expandedGoals.contains(index)) {
                      _expandedGoals.remove(index);
                    } else {
                      _expandedGoals.add(index);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.flag,
                        color: Color(0xFF2E3A59),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goalText,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Прогресс-бар
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: progress / 100,
                                      minHeight: 6,
                                      backgroundColor: isDark 
                                          ? Colors.white.withOpacity(0.1) 
                                          : (Colors.grey[300] ?? Colors.grey),
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E3A59)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${progress.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Иконка стрелки вниз/вверх
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: safeSubTextColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Кнопка удаления
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          final updatedGoals = List<Map<String, dynamic>>.from(_savedGoals);
                          updatedGoals.removeAt(index);
                          
                          // Сохраняем обновленный список
                          final goalsTextList = updatedGoals.map((g) => g['text'] as String).toList();
                          await prefs.setStringList('saved_goals_list', goalsTextList);
                          
                          // Удаляем сохраненный прогресс
                          await prefs.remove('goal_progress_${goalText.hashCode}');
                          
                          // Если удалили последнюю цель, обновляем основную
                          if (updatedGoals.isNotEmpty) {
                            await prefs.setString('user_goal', updatedGoals.last['text'] as String);
                          } else {
                            await prefs.remove('user_goal');
                          }
                          
                          if (mounted) {
                            setState(() {
                              _savedGoals = updatedGoals;
                            });
                          }
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Раскрывающаяся часть с полем редактирования
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: TextField(
                    controller: progressController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Накоплено (%)',
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: safeSubTextColor,
                      ),
                      filled: true,
                      fillColor: isDark 
                          ? Colors.white.withOpacity(0.05) 
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark 
                              ? Colors.white.withOpacity(0.1) 
                              : (Colors.grey[300] ?? Colors.grey),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (value) async {
                      final newProgress = double.tryParse(value) ?? 0.0;
                      if (newProgress >= 0 && newProgress <= 100) {
                        final prefs = await SharedPreferences.getInstance();
                        final updatedGoals = List<Map<String, dynamic>>.from(_savedGoals);
                        updatedGoals[index] = {
                          'text': goalText,
                          'progress': newProgress,
                        };
                        
                        // Сохраняем прогресс
                        await prefs.setDouble(
                          'goal_progress_${goalText.hashCode}',
                          newProgress,
                        );
                        
                        if (mounted) {
                          setState(() {
                            _savedGoals = updatedGoals;
                          });
                        }
                      }
                    },
                  ),
                ),
                crossFadeState: isExpanded 
                    ? CrossFadeState.showSecond 
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        );
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
          body: Column(
            children: [
              // Контейнер создания новой цели (сверху)
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Иконка и описание (уменьшены отступы)
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E3A59).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.flag,
                              size: 32,
                              color: Color(0xFF2E3A59),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.get('goals_subtitle'),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: subTextColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

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
                    const SizedBox(height: 20),

                    // Кнопка сохранения
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E3A59),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // Разделитель
              if (_savedGoals.isNotEmpty)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? Colors.white.withOpacity(0.1) : (Colors.grey[300] ?? Colors.grey),
                ),

              // Список сохраненных целей (сразу под контейнером создания)
              if (_savedGoals.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                        child: Text(
                          AppStrings.get('goals_saved_list_title'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _savedGoals.length,
                          itemBuilder: (context, index) {
                            final goal = _savedGoals[index];
                            final goalText = goal['text'] as String;
                            final progress = goal['progress'] as double;
                            
                            return _buildGoalCard(
                              context,
                              goalText: goalText,
                              progress: progress,
                              index: index,
                              isDark: isDark,
                              textColor: textColor,
                              subTextColor: subTextColor,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Text(
                      'Нет сохраненных целей',
                      style: TextStyle(
                        fontSize: 14,
                        color: subTextColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

