import 'dart:async';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'models.dart';
import 'chat_screen.dart';
import 'welcome_screen.dart';
import 'premium_screen.dart';
import 'theme_helper.dart';
import 'profile_screen.dart';
import 'localization.dart';
import 'usage_manager.dart';

// Глобальный ключ для доступа к MyAppState из любого места
final GlobalKey<_MyAppState> appStateKey = GlobalKey<_MyAppState>();

void main() {
  setAppStateKey(appStateKey);
  runApp(MyApp(key: appStateKey));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void toggleTheme() {
    if (!mounted) return;
    
    setState(() {
      switch (_themeMode) {
        case ThemeMode.system:
          // Переключаемся на светлую тему
          _themeMode = ThemeMode.light;
          break;
        case ThemeMode.light:
          // Переключаемся на темную тему
          _themeMode = ThemeMode.dark;
          break;
        case ThemeMode.dark:
          // Возвращаемся к системной теме
          _themeMode = ThemeMode.system;
          break;
      }
    });
  }

  IconData get themeIcon {
    switch (_themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 Слушаем изменения языка
    return ValueListenableBuilder<Language>(
      valueListenable: AppStrings.languageNotifier,
      builder: (context, language, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FinHack',
          
          // ☀️ СВЕТЛАЯ ТЕМА (Стандартная)
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2E3A59),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF5F5F7),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            cardColor: Colors.white,
            textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
          ),

          // 🌑 ТЕМНАЯ ТЕМА (Новая!)
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2E3A59),
              brightness: Brightness.dark,
              primary: const Color(0xFF6C84B8), // Чуть светлее для темного фона
              secondary: Colors.amber,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212), // Почти черный фон
            cardColor: const Color(0xFF1E1E1E), // Темно-серые карточки
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          ),

          // ⚙️ Ручное переключение темы
          themeMode: _themeMode, 
          
          home: const WelcomeScreen(),
        );
      },
    );
  }
}

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final ApiService _apiService = ApiService();
  FinanceData? _data;
  Map<String, dynamic>? _rawJson;
  bool _isLoading = false;
  String? _error;
  final List<Map<String, String>> _chatHistory = [];

  Future<void> _pickAndUpload() async {
    if (!mounted) return;
    setState(() => _error = null);

    // Проверяем лимит перед загрузкой
    final usageManager = UsageManager();
    final canProceed = await usageManager.canAction();
    
    if (!canProceed) {
      // Показываем диалог о лимите
      if (!mounted) return;
      final shouldGoToPremium = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppStrings.get('limit_exceeded_title')),
          content: Text(AppStrings.get('limit_exceeded_message')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppStrings.get('cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E3A59),
              ),
              child: Text(AppStrings.get('go_to_premium'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      
      if (shouldGoToPremium == true && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PremiumScreen()),
        );
      }
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        if (!mounted) return;
        setState(() => _isLoading = true);

        File file = File(result.files.single.path!);
        final jsonResponse = await _apiService.uploadStatement(file);
        
        // Увеличиваем счетчик использований только при успешной загрузке
        await usageManager.incrementUsage();
        
        if (!mounted) return;
        setState(() {
          _rawJson = jsonResponse;
          _data = FinanceData.fromJson(jsonResponse);
          _chatHistory.clear();
          _chatHistory.add({
            "role": "ai", 
            "text": "Привет! Я изучил твою выписку. Спроси меня: 'Сколько я потратил на такси?' или 'Как мне сэкономить?'"
          });
        });
      } 
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = "Не удалось загрузить. Проверьте сервер.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kztFormatter = NumberFormat.currency(symbol: '₸', decimalDigits: 0, locale: 'ru');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder<Language>(
          valueListenable: AppStrings.languageNotifier,
          builder: (context, language, child) {
            return Text(AppStrings.get('app_title'), style: const TextStyle(fontWeight: FontWeight.bold));
          },
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => ProfileScreen(
                onLogout: () {
                  // Эта функция сработает, когда в профиле нажмут "Выйти"
                  setState(() {
                    _data = null;
                    _rawJson = null;
                    _chatHistory.clear();
                  });
                },
              ))
            );
          },
        ),
        actions: [
          // Кнопка переключения темы
          StatefulBuilder(
            builder: (context, setState) {
              return IconButton(
                icon: Icon(getThemeIcon()),
                tooltip: 'Переключить тему',
                onPressed: () {
                  toggleTheme();
                  // Принудительно обновляем иконку
                  setState(() {});
                },
              );
            },
          ),
          // Кнопка премиума
          IconButton(
            icon: const Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())),
          ),
        ],
      ),
      floatingActionButton: (_data != null && _rawJson != null)
          ? ValueListenableBuilder<Language>(
              valueListenable: AppStrings.languageNotifier,
              builder: (context, language, child) {
                return FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => ChatScreen(
                        financeData: _data!, 
                        rawContext: _rawJson!,
                        messages: _chatHistory,
                      ))
                    );
                  },
                  label: Text(AppStrings.get('ai_chat_button'), style: const TextStyle(color: Colors.white)),
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                  backgroundColor: const Color(0xFF2E3A59),
                );
              },
            )
          : null,
      
      body: _isLoading
          ? const FunLoader()
          : _data == null
              ? _buildUploadButton()
              : _buildDashboard(kztFormatter, isDark),
    );
  }

  Widget _buildUploadButton() {
    return ValueListenableBuilder<Language>(
      valueListenable: AppStrings.languageNotifier,
      builder: (context, language, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.upload_file, size: 80, color: Colors.blueGrey[200]),
              const SizedBox(height: 20),
              Text(AppStrings.get('upload_screen_title'), style: const TextStyle(fontSize: 18)),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _pickAndUpload,
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(AppStrings.get('upload_screen_btn'), style: const TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E3A59),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboard(NumberFormat fmt, bool isDark) {
    return ValueListenableBuilder<Language>(
      valueListenable: AppStrings.languageNotifier,
      builder: (context, language, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2E3A59), Color(0xFF4B6CB7)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.get('total_spent'), style: const TextStyle(color: Colors.white70)),
                    Text(fmt.format(_data!.totalSpent), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text("${AppStrings.get('forecast')}: ${fmt.format(_data!.forecast)}", style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(AppStrings.get('categories_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: _data!.categories.map((cat) => PieChartSectionData(
                  color: cat.color,
                  value: cat.percent,
                  title: '${cat.percent.toInt()}%',
                  radius: 50,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                )).toList(),
              ),
            ),
          ),

          ..._data!.categories.take(5).map((cat) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: cat.color, radius: 5),
                const SizedBox(width: 10),
                Text(cat.name),
                const Spacer(),
                Text(fmt.format(cat.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )),

          const SizedBox(height: 20),

          if (_data!.advice.isNotEmpty)
            Card(
              color: isDark ? Colors.amber.withOpacity(0.1) : Colors.amber[50], // Адаптивный цвет
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.amber),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_data!.advice)),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          if (_data!.subscriptions.isNotEmpty) ...[
            Text(AppStrings.get('subs_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ..._data!.subscriptions.map((sub) => ListTile(
              leading: const Icon(Icons.subscriptions, color: Colors.red),
              title: Text(sub.name),
              trailing: Text(fmt.format(sub.cost), style: const TextStyle(fontWeight: FontWeight.bold)),
            )),
          ],

              const SizedBox(height: 40),
              Center(
                child: TextButton(
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        _data = null;
                        _rawJson = null;
                        _chatHistory.clear();
                      });
                    }
                  },
                  child: Text(AppStrings.get('upload_btn')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// (Код FunLoader остался таким же, можно оставить его внизу файла)
class FunLoader extends StatefulWidget {
  const FunLoader({super.key});

  @override
  State<FunLoader> createState() => _FunLoaderState();
}

class _FunLoaderState extends State<FunLoader> {
  int _index = 0;
  late final Stream<int> _timerStream;
  final List<String> _loadingPhrases = [
    "🤖 ИИ надевает очки...", "🧐 Изучаем траты...", "💸 Ищем деньги...",
    "🧹 Чистим данные...", "📊 Рисуем графики...", "🚀 Греем сервера...",
    "🤔 Вспоминаем курс...", "🍕 Хочется пиццы...", "🕵️‍♂️ Ищем подписки...", "✨ Почти всё..."
  ];

  StreamSubscription<int>? _subscription;

  @override
  void initState() {
    super.initState();
    _timerStream = Stream.periodic(const Duration(milliseconds: 2500), (i) => i);
    _subscription = _timerStream.listen((i) {
      if (mounted) {
        setState(() => _index = (i + 1) % _loadingPhrases.length);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF2E3A59)),
          const SizedBox(height: 40),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              _loadingPhrases[_index],
              key: ValueKey<String>(_loadingPhrases[_index]),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
