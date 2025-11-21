import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'localization.dart';
import 'usage_manager.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Language>(
      valueListenable: AppStrings.languageNotifier,
      builder: (context, language, child) {
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
                              AppStrings.get('premium_title'),
                              style: GoogleFonts.inter(
                                fontSize: 32, 
                                fontWeight: FontWeight.bold, 
                                color: Colors.white
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              AppStrings.get('premium_subtitle'),
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
                      _buildPremiumFeature(AppStrings.get('premium_feature1')),
                      const SizedBox(height: 15),
                      _buildPremiumFeature(AppStrings.get('premium_feature2')),
                      const SizedBox(height: 15),
                      _buildPremiumFeature(AppStrings.get('premium_feature3')),
                      const SizedBox(height: 15),
                      _buildPremiumFeature(AppStrings.get('premium_feature4')),
                      
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
                              AppStrings.get('premium_price'),
                              style: GoogleFonts.inter(
                                fontSize: 24, 
                                fontWeight: FontWeight.bold, 
                                color: Colors.white
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              AppStrings.get('premium_trial'),
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
                                onPressed: () async {
                                  // Активируем премиум
                                  final usageManager = UsageManager();
                                  await usageManager.setPremium();
                                  
                                  // Показываем уведомление
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(AppStrings.get('premium_activated')),
                                        backgroundColor: Colors.green,
                                      )
                                    );
                                    Navigator.pop(context);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black87,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)
                                  ),
                                ),
                                child: Text(
                                  AppStrings.get('premium_button'),
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
      },
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