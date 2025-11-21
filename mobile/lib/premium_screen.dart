import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E3A59), // Наш фирменный фон
      body: Stack(
        children: [
          // Фоновый декоративный круг
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Кнопка закрыть
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.white70, size: 30),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Заголовок
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.workspace_premium, color: Colors.amber, size: 80),
                        const SizedBox(height: 20),
                        Text(
                          "FinHack PRO",
                          style: GoogleFonts.inter(
                            fontSize: 32, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.white
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Разблокируй полную мощь AI",
                          style: GoogleFonts.inter(
                            fontSize: 16, 
                            color: Colors.white70
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Список преимуществ
                  _buildPremiumFeature("Безлимитные вопросы к AI"),
                  const SizedBox(height: 15),
                  _buildPremiumFeature("Глубокий анализ долгов"),
                  const SizedBox(height: 15),
                  _buildPremiumFeature("Экспорт отчетов в Excel"),
                  const SizedBox(height: 15),
                  _buildPremiumFeature("Семейный доступ"),
                  
                  const Spacer(),
                  
                  // Цена и кнопка
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.withOpacity(0.3))
                    ),
                    child: Column(
                      children: [
                        Text(
                          "990 ₸ / месяц",
                          style: GoogleFonts.inter(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.white
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Первые 7 дней бесплатно",
                          style: GoogleFonts.inter(
                            fontSize: 14, 
                            color: Colors.amberAccent
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: () {
                              // Фейковая покупка
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Демо режим: Покупка успешна!"))
                              );
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)
                              ),
                            ),
                            child: Text(
                              "Оформить подписку",
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeature(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.amber, size: 24),
        const SizedBox(width: 15),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 18, 
            color: Colors.white,
            fontWeight: FontWeight.w500
          ),
        ),
      ],
    );
  }
}