import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart'; // Чтобы видеть FinanceScreen

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E3A59), // Темно-синий фон
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Верхняя часть: Заголовок и иконка
              Column(
                children: [
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome, 
                      size: 80, 
                      color: Colors.amberAccent
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "FinHack AI",
                    style: GoogleFonts.inter(
                      fontSize: 36, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Твой умный финансовый ассистент",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16, 
                      color: Colors.white70
                    ),
                  ),
                ],
              ),

              // Центральная часть: Список преимуществ
              Column(
                children: [
                  _buildFeatureItem(Icons.upload_file, "Загрузи выписку Kaspi PDF"),
                  const SizedBox(height: 20),
                  _buildFeatureItem(Icons.pie_chart, "Получи аналитику и советы"),
                  const SizedBox(height: 20),
                  _buildFeatureItem(Icons.chat, "Общайся с AI о финансах"),
                ],
              ),

              // Кнопка
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    // Переход на главный экран (без возможности вернуться назад)
                    Navigator.pushReplacement(
                      context, 
                      MaterialPageRoute(builder: (_) => const FinanceScreen())
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2E3A59),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    "Начать анализ",
                    style: GoogleFonts.inter(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 16, 
              color: Colors.white, 
              fontWeight: FontWeight.w500
            ),
          ),
        ),
      ],
    );
  }
}

