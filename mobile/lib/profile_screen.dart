import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'welcome_screen.dart';
import 'premium_screen.dart';

class ProfileScreen extends StatefulWidget {
  // Принимаем функцию для сброса данных, которую передадим с главного экрана
  final VoidCallback onLogout;

  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifications = true;
  bool _faceId = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.grey[600];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Профиль", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Аватар и Имя
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF2E3A59),
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              "Амир Аханов", // Хардкод для соответствия PDF
              style: GoogleFonts.inter(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Text(
              "amir.akhanov@gmail.com",
              style: GoogleFonts.inter(fontSize: 14, color: subTextColor),
            ),
            const SizedBox(height: 24),

            // Карточка статуса
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2C) : Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_border, color: Colors.blue, size: 30),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Текущий план: Free",
                        style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                      ),
                      Text(
                        "Лимит: 5 запросов/день",
                        style: TextStyle(fontSize: 12, color: subTextColor),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text("Upgrade"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            
            // Настройки (Фейковые, просто для красоты)
            _buildSwitchTile("Уведомления", "Отчеты о тратах", _notifications, (v) => setState(() => _notifications = v)),
            _buildSwitchTile("Вход по Face ID", "Быстрый доступ", _faceId, (v) => setState(() => _faceId = v)),
            
            const Divider(height: 40),

            // Опасная зона
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.logout, color: Colors.red),
              ),
              title: const Text("Выйти из аккаунта", style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                // Сброс данных и выход
                widget.onLogout(); 
                
                // Возврат на экран приветствия (удаляя все предыдущие экраны из истории)
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
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      value: value,
      activeColor: const Color(0xFF2E3A59),
      onChanged: onChanged,
    );
  }
}