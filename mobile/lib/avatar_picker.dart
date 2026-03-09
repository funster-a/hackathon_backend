import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Дефолтный аватар — комбинация цвета и иконки
class DefaultAvatar {
  final String id;
  final Color backgroundColor;
  final IconData icon;

  const DefaultAvatar({
    required this.id,
    required this.backgroundColor,
    required this.icon,
  });
}

/// Галерея дефолтных аватарок + пользовательское фото
class AvatarGallery {
  static const String _storageKey = 'selected_avatar_id';
  static const String _customPathKey = 'avatar_custom_path';
  static const String _customPathsKey = 'avatar_custom_paths'; // галерея загруженных
  static const String _customId = 'custom';
  static const int _maxGallerySize = 10;

  static const List<DefaultAvatar> avatars = [
    DefaultAvatar(
      id: '0',
      backgroundColor: Color(0xFF2E3A59),
      icon: Icons.person,
    ),
    DefaultAvatar(
      id: '1',
      backgroundColor: Color(0xFF4B6CB7),
      icon: Icons.account_circle,
    ),
    DefaultAvatar(
      id: '2',
      backgroundColor: Color(0xFF2196F3),
      icon: Icons.face,
    ),
    DefaultAvatar(
      id: '3',
      backgroundColor: Color(0xFF00BCD4),
      icon: Icons.savings,
    ),
    DefaultAvatar(
      id: '4',
      backgroundColor: Color(0xFF4CAF50),
      icon: Icons.star,
    ),
    DefaultAvatar(
      id: '5',
      backgroundColor: Color(0xFF8BC34A),
      icon: Icons.lightbulb_outline,
    ),
    DefaultAvatar(
      id: '6',
      backgroundColor: Color(0xFF9C27B0),
      icon: Icons.favorite,
    ),
    DefaultAvatar(
      id: '7',
      backgroundColor: Color(0xFFE91E63),
      icon: Icons.diamond,
    ),
    DefaultAvatar(
      id: '8',
      backgroundColor: Color(0xFFFF5722),
      icon: Icons.trending_up,
    ),
    DefaultAvatar(
      id: '9',
      backgroundColor: Color(0xFFFF9800),
      icon: Icons.account_balance_wallet,
    ),
    DefaultAvatar(
      id: '10',
      backgroundColor: Color(0xFF3F51B5),
      icon: Icons.pie_chart,
    ),
    DefaultAvatar(
      id: '11',
      backgroundColor: Color(0xFF607D8B),
      icon: Icons.attach_money,
    ),
  ];

  static DefaultAvatar getDefault() => avatars.first;

  static DefaultAvatar getById(String? id) {
    if (id == null) return getDefault();
    if (id == _customId) return getDefault(); // custom показывается через buildAvatarFromPath
    return avatars.firstWhere(
      (a) => a.id == id,
      orElse: () => getDefault(),
    );
  }

  static String get storageKey => _storageKey;
  static String get customPathKey => _customPathKey;
  static String get customId => _customId;

  /// Путь к пользовательскому фото (если есть)
  static Future<String?> getCustomAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_customPathKey);
    if (path == null) return null;
    final file = File(path);
    return file.existsSync() ? path : null;
  }

  /// Сохранить путь к пользовательскому фото
  static Future<void> setCustomAvatarPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_customPathKey);
      await prefs.setString(_storageKey, '0');
    } else {
      await prefs.setString(_customPathKey, path);
      await prefs.setString(_storageKey, _customId);
      await _addToGallery(path, prefs);
    }
  }

  static Future<void> _addToGallery(String path, SharedPreferences prefs) async {
    final list = prefs.getStringList(_customPathsKey) ?? [];
    if (list.contains(path)) return;
    final newList = [path, ...list.where((p) => p != path).take(_maxGallerySize - 1)];
    await prefs.setStringList(_customPathsKey, newList);
  }

  /// Получить список загруженных фото
  static Future<List<String>> getCustomAvatarPaths() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_customPathsKey) ?? [];
    final singlePath = prefs.getString(_customPathKey);
    if (singlePath != null && !list.contains(singlePath) && File(singlePath).existsSync()) {
      list = [singlePath, ...list];
      await prefs.setStringList(_customPathsKey, list);
    }
    return list.where((p) => File(p).existsSync()).toList();
  }

  /// Выбрать фото из галереи
  static Future<String?> pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (xFile == null) return null;

      final appDir = await getApplicationDocumentsDirectory();
      final avatarDir = Directory('${appDir.path}/avatars');
      if (!await avatarDir.exists()) await avatarDir.create(recursive: true);

      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final destPath = '${avatarDir.path}/$fileName';
      await File(xFile.path).copy(destPath);
      return destPath;
    } catch (e) {
      debugPrint('Avatar pick error: $e');
      return null;
    }
  }

  /// Виджет аватарки по пути к файлу
  static Widget buildAvatarFromPath({
    required String path,
    double radius = 50,
    bool showBorder = false,
    Color? borderColor,
    Key? key,
  }) {
    final file = File(path);
    if (!file.existsSync()) {
      return CircleAvatar(radius: radius, child: Icon(Icons.broken_image, size: radius));
    }
    return Container(
      key: key ?? ValueKey(path),
      decoration: showBorder
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor ?? Colors.amber,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            )
          : null,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF2E3A59),
        backgroundImage: FileImage(file),
      ),
    );
  }

  static Widget buildAvatar({
    required DefaultAvatar avatar,
    double radius = 50,
    bool showBorder = false,
    Color? borderColor,
  }) {
    return Container(
      decoration: showBorder
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor ?? avatar.backgroundColor,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: avatar.backgroundColor.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            )
          : null,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: avatar.backgroundColor,
        child: Icon(avatar.icon, size: radius * 1.0, color: Colors.white),
      ),
    );
  }
}
