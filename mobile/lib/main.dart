import 'dart:async';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'models.dart';
import 'welcome_screen.dart';
import 'premium_screen.dart';
import 'profile_screen.dart';
import 'localization.dart';
import 'usage_manager.dart';
import 'alert_helper.dart';
import 'theme_helper.dart';

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
          _themeMode = ThemeMode.light;
          break;
        case ThemeMode.light:
          _themeMode = ThemeMode.dark;
          break;
        case ThemeMode.dark:
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
    return ValueListenableBuilder<Language>(
      valueListenable: AppStrings.languageNotifier,
      builder: (context, language, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Startup Analyzer',
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
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2E3A59),
              brightness: Brightness.dark,
              primary: const Color(0xFF6C84B8),
              secondary: Colors.amber,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          ),
          themeMode: _themeMode,
          home: const WelcomeScreen(),
        );
      },
    );
  }
}

class FinanceScreen extends StatefulWidget {
  // Обратите внимание: теперь тут StartupPlanData вместо FinanceData
  final Function(StartupPlanData, Map<String, dynamic>)? onChatRequested;

  const FinanceScreen({super.key, this.onChatRequested});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _ideaController = TextEditingController();

  StartupPlanData? _data;
  Map<String, dynamic>? _rawJson;
  bool _isLoading = false;
  String? _error;

  Future<void> _submitIdea() async {
    if (_ideaController.text.trim().isEmpty) {
      setState(() => _error = "Пожалуйста, опишите идею стартапа");
      return;
    }

    if (!mounted) return;
    setState(() => _error = null);

    final usageManager = UsageManager();
    final canProceed = await usageManager.canAction();

    if (!canProceed) {
      if (!mounted) return;
      await showLiquidGlassDialog<bool>(
        context: context,
        title: AppStrings.get('limit_exceeded_title'),
        message: AppStrings.get('limit_exceeded_message'),
        confirmText: AppStrings.get('go_to_premium'),
        cancelText: AppStrings.get('cancel'),
        onConfirm: () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PremiumScreen()),
            );
          }
        },
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final jsonResponse = await _apiService.calculateStartupPlan(
        _ideaController.text,
      );

      if (jsonResponse.isEmpty) throw Exception("Пустой ответ от сервера");

      final planData = StartupPlanData.fromJson(jsonResponse);

      await usageManager.incrementUsage();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('finance_data_json', jsonEncode(jsonResponse));

      if (widget.onChatRequested != null) {
        widget.onChatRequested!(planData, jsonResponse);
      }

      if (!mounted) return;
      setState(() {
        _rawJson = jsonResponse;
        _data = planData;
      });
    } catch (e) {
      if (!mounted) return;
      final errorMessage = e.toString();
      setState(() {
        _error =
            "Ошибка расчета: ${errorMessage.length > 100 ? errorMessage.substring(0, 100) : errorMessage}";
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kztFormatter = NumberFormat.currency(
      symbol: '₸',
      decimalDigits: 0,
      locale: 'ru',
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isInContainer = widget.onChatRequested != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'План Стартапа',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: isInContainer
            ? null
            : IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(
                        onLogout: () {
                          setState(() {
                            _data = null;
                            _rawJson = null;
                            _ideaController.clear();
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
        actions: [
          StatefulBuilder(
            builder: (context, setState) {
              return IconButton(
                icon: Icon(
                  appStateKey.currentState?.themeIcon ?? Icons.brightness_auto,
                ),
                onPressed: () {
                  appStateKey.currentState?.toggleTheme();
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.workspace_premium,
              color: Colors.amber,
              size: 28,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PremiumScreen()),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const FunLoader()
          : _data == null
          ? _buildInputScreen()
          : _buildDashboard(kztFormatter, isDark),
    );
  }

  Widget _buildInputScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rocket_launch, size: 80, color: Colors.blueGrey[200]),
            const SizedBox(height: 20),
            const Text(
              'Опишите идею вашего стартапа',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ideaController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText:
                    'Например: маркетплейс для поиска репетиторов с ИИ-подбором...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _submitIdea,
              icon: const Icon(Icons.analytics, color: Colors.white),
              label: const Text(
                'Рассчитать смету',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E3A59),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(NumberFormat fmt, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E3A59), Color(0xFF4B6CB7)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Необходимый бюджет',
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  fmt.format(_data!.totalBudget),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Burn Rate / мес',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          fmt.format(_data!.monthlyBurnRate),
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Runway',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          '${_data!.runwayMonths} мес.',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_data!.categories.isNotEmpty) ...[
            const Text(
              'Распределение бюджета',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: _data!.categories.map((cat) {
                    return PieChartSectionData(
                      color: cat.color,
                      value: cat.percent,
                      title: '${cat.percent.toInt()}%\n${cat.name}',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ..._data!.categories.map(
              (cat) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(backgroundColor: cat.color, radius: 5),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        cat.name,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    Text(
                      fmt.format(cat.amount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (_data!.advice.isNotEmpty)
            Card(
              color: isDark ? Colors.blue.withOpacity(0.1) : Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_data!.advice)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),

          if (_data!.team.isNotEmpty) ...[
            const Text(
              'Команда MVP',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._data!.team.map(
              (member) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueGrey.withOpacity(0.2),
                    child: const Icon(Icons.person, color: Colors.blueGrey),
                  ),
                  title: Text(
                    member.role,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  subtitle: Text(
                    member.stack,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  trailing: Text(
                    '${fmt.format(member.salary)}/мес',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 40),
          Center(
            child: TextButton(
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _data = null;
                    _rawJson = null;
                    _ideaController.clear();
                  });
                }
              },
              child: const Text('Рассчитать другую идею'),
            ),
          ),
        ],
      ),
    );
  }
}

class FunLoader extends StatefulWidget {
  const FunLoader({super.key});

  @override
  State<FunLoader> createState() => _FunLoaderState();
}

class _FunLoaderState extends State<FunLoader> {
  int _index = 0;
  late final Stream<int> _timerStream;
  final List<String> _loadingPhrases = [
    "🤖 ИИ оценивает идею...",
    "💼 Считаем зарплаты...",
    "🚀 Выбираем сервера...",
    "📈 Формируем бюджет...",
    "💸 Ищем инвесторов...",
    "✨ Почти всё...",
  ];

  StreamSubscription<int>? _subscription;

  @override
  void initState() {
    super.initState();
    _timerStream = Stream.periodic(
      const Duration(milliseconds: 2500),
      (i) => i,
    );
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
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
