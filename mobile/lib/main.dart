import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'models.dart';

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
  bool _isLoading = false;
  String? _error;

  Future<void> _pickAndUpload() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        final data = await _apiService.uploadStatement(file);
        setState(() => _data = data);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _error = "Ошибка загрузки. Проверьте сервер (python main.py)");
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
      body: _isLoading
          ? _buildLoading()
          : _data == null
          ? _buildUploadButton()
          : _buildDashboard(kztFormatter),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text("ИИ анализирует расходы...", style: GoogleFonts.inter(fontSize: 16)),
        ],
      ),
    );
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
              onPressed: () => setState(() => _data = null),
              child: const Text("Загрузить другой файл"),
            ),
          ),
        ],
      ),
    );
  }
}