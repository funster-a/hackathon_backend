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

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 300),
    ),
  );

  // 👇 НОВЫЙ МЕТОД ДЛЯ РАСЧЕТА СТАРТАПА (Вместо загрузки PDF) 👇
  Future<Map<String, dynamic>> calculateStartupPlan(
    String ideaDescription,
  ) async {
    try {
      final language = AppStrings.languageCode;
      // Обратите внимание: эндпоинт изменен на /analyze_startup
      Response response = await _dio.post(
        '$_baseUrl/analyze_startup',
        data: {"description": ideaDescription},
        queryParameters: {'language': language},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Метод для чата (адаптирован под стартапы)
  Future<String> sendChatMessage(
    String question,
    Map<String, dynamic> fullJsonContext,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Меняем дефолтную цель на актуальную для контекста
      final userGoal = prefs.getString('user_goal') ?? 'Запуск успешного MVP';

      final response = await _dio.post(
        '$_baseUrl/chat',
        data: {
          "question": question,
          "context": fullJsonContext,
          "language": AppStrings.languageCode,
          "user_goal": userGoal,
        },
      );
      return response.data['reply'];
    } catch (e) {
      return AppStrings.get('chat_error');
    }
  }
}
