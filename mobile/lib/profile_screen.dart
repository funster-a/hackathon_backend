import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_screen.dart';
import 'premium_screen.dart';
import 'localization.dart';
import 'usage_manager.dart';
import 'goals_screen.dart';
import 'pin_screen.dart';
import 'alert_helper.dart';
import 'avatar_picker.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UsageManager _usageManager = UsageManager();
  String? _userName;
  DefaultAvatar _selectedAvatar = AvatarGallery.getDefault();
  String? _customAvatarPath;
  List<String> _customAvatarPaths = [];
  
  // Состояния для плавного отображения без FutureBuilder в методе build
  bool _isPinSet = false;
  bool _isPremium = false;
  int _remainingAttempts = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name');
    final avatarId = prefs.getString(AvatarGallery.storageKey);
    final customPath = await AvatarGallery.getCustomAvatarPath();
    final customPaths = await AvatarGallery.getCustomAvatarPaths();
    
    final pinStatus = await PinScreen.isPinSet();
    final isPrem = await _usageManager.isPremium;
    final remaining = await _usageManager.remainingAttempts;

    if (mounted) {
      setState(() {
        _userName = name;
        _customAvatarPath = customPath;
        _customAvatarPaths = customPaths;
        _selectedAvatar = AvatarGallery.getById(avatarId);
        _isPinSet = pinStatus;
        _isPremium = isPrem;
        _remainingAttempts = remaining;
      });
    }
  }

  Future<void> _saveAvatar(DefaultAvatar avatar) async {
    await AvatarGallery.setCustomAvatarPath(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AvatarGallery.storageKey, avatar.id);
    if (mounted) {
      setState(() {
        _selectedAvatar = avatar;
        _customAvatarPath = null;
      });
    }
  }

  Future<void> _pickCustomPhoto(BuildContext sheetContext) async {
    final path = await AvatarGallery.pickFromGallery();
    if (!mounted) return;
    if (path != null) {
      await AvatarGallery.setCustomAvatarPath(path);
      final customPaths = await AvatarGallery.getCustomAvatarPaths();
      if (sheetContext.mounted) Navigator.pop(sheetContext);
      if (mounted) {
        setState(() {
          _customAvatarPath = path;
          _customAvatarPaths = customPaths;
          _selectedAvatar = AvatarGallery.getDefault();
        });
      }
    }
  }

  void _showAvatarPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.get('avatar_dialog_title'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _pickCustomPhoto(sheetContext),
                icon: const Icon(Icons.photo_library, size: 24),
                label: Text(AppStrings.get('avatar_from_gallery')),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: const Color(0xFF2E3A59),
                  side: const BorderSide(color: Color(0xFF2E3A59)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_customAvatarPaths.isNotEmpty) ...[
              Text(
                AppStrings.get('avatar_uploaded'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _customAvatarPaths.map((path) {
                  final isSelected = _customAvatarPath == path;
                  return GestureDetector(
                    onTap: () async {
                      await AvatarGallery.setCustomAvatarPath(path);
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                      if (mounted) setState(() => _customAvatarPath = path);
                    },
                    child: AvatarGallery.buildAvatarFromPath(
                      path: path,
                      radius: 36,
                      showBorder: isSelected,
                      borderColor: Colors.amber,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              AppStrings.get('avatar_defaults'),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: AvatarGallery.avatars.map((avatar) {
                final isSelected = _customAvatarPath == null && _selectedAvatar.id == avatar.id;
                return GestureDetector(
                  onTap: () {
                    _saveAvatar(avatar);
                    Navigator.pop(sheetContext);
                  },
                  child: AvatarGallery.buildAvatar(
                    avatar: avatar,
                    radius: 32,
                    showBorder: isSelected,
                    borderColor: Colors.amber,
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    if (_customAvatarPath != null) {
      return AvatarGallery.buildAvatarFromPath(path: _customAvatarPath!, radius: 50);
    }
    return AvatarGallery.buildAvatar(avatar: _selectedAvatar, radius: 50);
  }

  Widget _buildAvatarLeading() {
    if (_customAvatarPath != null) {
      return AvatarGallery.buildAvatarFromPath(path: _customAvatarPath!, radius: 20);
    }
    return AvatarGallery.buildAvatar(avatar: _selectedAvatar, radius: 20);
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
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _showAvatarPicker,
                  child: Stack(
                    children: [
                      _buildProfileAvatar(),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E3A59),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(Icons.edit, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _userName ?? AppStrings.get('profile_guest'),
                  style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 30),

                // ВЫБОР ЯЗЫКА
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
                      AppStrings.setLanguage(newSelection.first);
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                        if (states.contains(WidgetState.selected)) return const Color(0xFF2E3A59);
                        return null;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                        if (states.contains(WidgetState.selected)) return Colors.white;
                        return isDark ? Colors.white : Colors.black;
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Смена аватарки
                ListTile(
                  leading: _buildAvatarLeading(),
                  title: Text(AppStrings.get('avatar_menu_item'), style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showAvatarPicker,
                ),
                const SizedBox(height: 16),

                // Карточка статуса (без FutureBuilder)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2C) : Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isPremium ? Icons.star : Icons.star_border,
                        color: _isPremium ? Colors.amber : Colors.blue,
                        size: 30,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isPremium ? AppStrings.get('status_premium') : AppStrings.get('status_free'),
                            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                          ),
                          Text(
                            _isPremium ? AppStrings.get('unlimited') : '${AppStrings.get('remaining')}: $_remainingAttempts',
                            style: TextStyle(fontSize: 12, color: subTextColor),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (!_isPremium)
                        ElevatedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PremiumScreen()),
                            );
                            _loadUserData(); // Обновляем данные после возврата
                          },
                          child: Text(AppStrings.get('upgrade')),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 40),

                // Финансовые цели
                ListTile(
                  leading: const Icon(Icons.flag, color: Color(0xFF2E3A59)),
                  title: Text(AppStrings.get('goals_menu_item'), style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen()));
                  },
                ),
                const Divider(height: 20),

                // ПИН-код (без FutureBuilder)
                ListTile(
                  leading: const Icon(Icons.lock, color: Color(0xFF2E3A59)),
                  title: Text(
                    _isPinSet ? AppStrings.get('pin_menu_change') : AppStrings.get('pin_menu_setup'),
                    style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    if (_isPinSet) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PinScreen(mode: PinMode.change)),
                      );
                      if (result == true && mounted) {
                        _loadUserData();
                        showSuccessAlert(context, message: AppStrings.get('pin_menu_change'));
                      }
                    } else {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PinScreen(mode: PinMode.setup)),
                      );
                      if (result == true && mounted) {
                        _loadUserData();
                        showSuccessAlert(context, message: AppStrings.get('pin_menu_setup'));
                      }
                    }
                  },
                ),
                const Divider(height: 20),

                // Выход
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
}