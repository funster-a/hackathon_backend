import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'welcome_screen.dart';
import 'premium_screen.dart';
import 'localization.dart'; // Импорт локализации
import 'usage_manager.dart';
import 'goals_screen.dart';
import 'pin_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UsageManager _usageManager = UsageManager();

  @override
  void initState() {
    super.initState();
    // Обновляем состояние при возврате на экран
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
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
            title: Text(AppStrings.get('profile_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
            elevation: 0,
            automaticallyImplyLeading: false, // Убираем кнопку назад для работы в табах
          ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF2E3A59),
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              "Амир Аханов",
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
            ),
            Text(
              "amir.akhanov@gmail.com",
              style: GoogleFonts.inter(fontSize: 14, color: subTextColor),
            ),
            const SizedBox(height: 30),

            // 🔥 ВЫБОР ЯЗЫКА
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppStrings.get('settings_lang'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<Language>(
                segments: const [
                  ButtonSegment(value: Language.ru, label: Text("Рус")),
                  ButtonSegment(value: Language.kz, label: Text("Қаз")),
                  ButtonSegment(value: Language.en, label: Text("Eng")),
                ],
                selected: {AppStrings.currentLanguage},
                onSelectionChanged: (Set<Language> newSelection) {
                  setState(() {
                    // Обновляем язык глобально
                    AppStrings.setLanguage(newSelection.first);
                  });
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(MaterialState.selected)) {
                      return const Color(0xFF2E3A59);
                    }
                    return null;
                  }),
                  foregroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(MaterialState.selected)) {
                      return Colors.white;
                    }
                    return isDark ? Colors.white : Colors.black;
                  }),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Карточка статуса
            FutureBuilder<Map<String, dynamic>>(
              future: _getStatusInfo(),
              builder: (context, snapshot) {
                final isPremium = snapshot.data?['isPremium'] ?? false;
                final remaining = snapshot.data?['remaining'] ?? 0;
                
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2C) : Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPremium ? Icons.star : Icons.star_border,
                        color: isPremium ? Colors.amber : Colors.blue,
                        size: 30,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPremium 
                              ? AppStrings.get('status_premium')
                              : AppStrings.get('status_free'),
                            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                          ),
                          Text(
                            isPremium
                              ? AppStrings.get('unlimited')
                              : '${AppStrings.get('remaining')}: $remaining',
                            style: TextStyle(fontSize: 12, color: subTextColor),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (!isPremium)
                        ElevatedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PremiumScreen()),
                            );
                            // Обновляем состояние после возврата
                            if (mounted) setState(() {});
                          },
                          child: Text(AppStrings.get('upgrade')),
                        ),
                    ],
                  ),
                );
              },
            ),

            const Divider(height: 40),

            // Финансовые цели
            ListTile(
              leading: const Icon(Icons.flag, color: Color(0xFF2E3A59)),
              title: Text(AppStrings.get('goals_menu_item'), style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GoalsScreen()),
                );
              },
            ),

            const Divider(height: 20),

            // ПИН-код
            FutureBuilder<bool>(
              future: PinScreen.isPinSet(),
              builder: (context, snapshot) {
                final isPinSet = snapshot.data ?? false;
                return ListTile(
                  leading: const Icon(Icons.lock, color: Color(0xFF2E3A59)),
                  title: Text(
                    isPinSet 
                        ? AppStrings.get('pin_menu_change')
                        : AppStrings.get('pin_menu_setup'),
                    style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    if (isPinSet) {
                      // Изменение PIN-кода
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PinScreen(mode: PinMode.change),
                        ),
                      );
                      if (result == true && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppStrings.get('pin_menu_change')),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else {
                      // Установка PIN-кода
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PinScreen(mode: PinMode.setup),
                        ),
                      );
                      if (result == true && mounted) {
                        setState(() {}); // Обновляем состояние для обновления текста кнопки
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppStrings.get('pin_menu_setup')),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                );
              },
            ),

            const Divider(height: 20),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(AppStrings.get('logout'), style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
              onTap: () {
                widget.onLogout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getStatusInfo() async {
    final isPremium = await _usageManager.isPremium;
    final remaining = await _usageManager.remainingAttempts;
    return {
      'isPremium': isPremium,
      'remaining': remaining,
    };
  }
}