import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'models.dart';
import 'chat_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E3A59)),
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      ),
      home: const FinanceScreen(),
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

  // 🔥 ХРАНИЛИЩЕ ИСТОРИИ ЧАТА (чтобы не пропадало)
  final List<Map<String, String>> _chatHistory = [];

  Future<void> _pickAndUpload() async {
    setState(() {
      _error = null;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        setState(() {
          _isLoading = true;
        });

        File file = File(result.files.single.path!);
        
        // Отправляем на сервер
        // (Убедись, что в api_service.dart метод uploadStatement возвращает Map!)
        final jsonResponse = await _apiService.uploadStatement(file);
        
        setState(() {
          _rawJson = jsonResponse;
          _data = FinanceData.fromJson(jsonResponse);
          
          // 🔥 Сбрасываем чат для нового файла
          _chatHistory.clear();
          _chatHistory.add({
            "role": "ai", 
            "text": "Привет! Я изучил твою выписку. Спроси меня: 'Сколько я потратил на такси?' или 'Как мне сэкономить?'"
          });
        });
      } 
    } catch (e) {
      setState(() => _error = "Не удалось загрузить. Проверьте сервер (python main.py).");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kztFormatter = NumberFormat.currency(symbol: '₸', decimalDigits: 0, locale: 'ru');

    return Scaffold(
      appBar: AppBar(
        title: const Text("FinHack", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      // 🔥 Кнопка теперь ПРАВИЛЬНО внутри Scaffold
      floatingActionButton: (_data != null && _rawJson != null)
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => ChatScreen(
                    financeData: _data!, 
                    rawContext: _rawJson!,
                    messages: _chatHistory, // Передаем историю
                  ))
                );
              },
              label: const Text("AI Чат", style: TextStyle(color: Colors.white)),
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              backgroundColor: const Color(0xFF2E3A59),
            )
          : null,
      
      body: _isLoading
          ? _buildLoading()
          : _data == null
              ? _buildUploadButton()
              : _buildDashboard(kztFormatter),
    );
  }

  Widget _buildLoading() {
    return const FunLoader();
  }

  Widget _buildUploadButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.upload_file, size: 80, color: Colors.blueGrey[200]),
          const SizedBox(height: 20),
          const Text("Загрузите выписку Kaspi (PDF)", style: TextStyle(fontSize: 18)),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _pickAndUpload,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Выбрать файл", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E3A59),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(NumberFormat fmt) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Карточка с суммой
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
                const Text("Всего потрачено", style: TextStyle(color: Colors.white70)),
                Text(fmt.format(_data!.totalSpent), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text("Прогноз: ${fmt.format(_data!.forecast)}", style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // График
          const Text("Анализ категорий", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

          // Легенда графика
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

          // Совет
          if (_data!.advice.isNotEmpty)
            Card(
              color: Colors.amber[50],
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

          // Подписки
          if (_data!.subscriptions.isNotEmpty) ...[
            const Text("Подписки", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ..._data!.subscriptions.map((sub) => ListTile(
              leading: const Icon(Icons.subscriptions, color: Colors.red),
              title: Text(sub.name),
              trailing: Text(fmt.format(sub.cost), style: const TextStyle(fontWeight: FontWeight.bold)),
            )),
          ],

          const SizedBox(height: 40),
          Center(
            child: TextButton(
              onPressed: () => setState(() {
                _data = null;
                _rawJson = null;
                _chatHistory.clear();
              }),
              child: const Text("Загрузить другой файл"),
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
    "🤖 ИИ надевает очки...",
    "🧐 Изучаем ваши траты на кофе...",
    "💸 Ищем, куда делись деньги...",
    "🧹 Выметаем скрытые комиссии...",
    "📊 Рисуем красивые графики...",
    "🚀 Подогреваем сервера...",
    "🤔 Вспоминаем курс тенге...",
    "🍕 Может, заказать пиццу пока ждем?",
    "🕵️‍♂️ Детектим подписки...",
    "✨ Почти готово...",
  ];

  @override
  void initState() {
    super.initState();
    _timerStream = Stream.periodic(const Duration(milliseconds: 2500), (i) => i);
    _timerStream.listen((i) {
      if (mounted) {
        setState(() {
          _index = (i + 1) % _loadingPhrases.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E3A59)),
                backgroundColor: Colors.black12,
              ),
            ),
            const SizedBox(height: 40),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.5),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Text(
                _loadingPhrases[_index],
                key: ValueKey<String>(_loadingPhrases[_index]),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2E3A59),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Это может занять до 20 секунд",
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}