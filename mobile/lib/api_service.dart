import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'localization.dart';

class ApiService {
  static String get _baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://172.16.3.124:8000';
    }
  }  
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 300), // Увеличиваем таймаут до 5 минут для DeepSeek API
  ));

  // Загрузка файла (уже было)
  Future<Map<String, dynamic>> uploadStatement(File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });
      // Передаем текущий язык приложения
      final language = AppStrings.languageCode;
      Response response = await _dio.post(
        '$_baseUrl/analyze',
        data: formData,
        queryParameters: {'language': language},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // 👇 НОВЫЙ МЕТОД ДЛЯ ЧАТА 👇
  Future<String> sendChatMessage(String question, Map<String, dynamic> fullJsonContext) async {
    try {
      // 📖 ИСПОЛЬЗОВАНИЕ: Загружаем сохраненную финансовую цель из SharedPreferences
      // Ключ: 'user_goal'
      // Сохранение: goals_screen.dart -> _saveData()
      // Отправляется на бэкенд: backend/main.py -> ChatRequest.user_goal -> используется в системном промпте
      final prefs = await SharedPreferences.getInstance();
      final userGoal = prefs.getString('user_goal') ?? '';
      
      final response = await _dio.post(
        '$_baseUrl/chat',
        data: {
          "question": question,
          "context": fullJsonContext,
          "language": AppStrings.languageCode, // Передаем текущий язык приложения
          "user_goal": userGoal, // Добавляем финансовую цель пользователя
        },
      );
      return response.data['reply'];
    } catch (e) {
      return AppStrings.get('chat_error');
    }
  }
}