import 'dart:io';
import 'package:dio/dio.dart';
import 'localization.dart';

class ApiService {
  static String get _baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://127.0.0.1:8000';
    }
  }  
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 60),
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
      final response = await _dio.post(
        '$_baseUrl/chat',
        data: {
          "question": question,
          "context": fullJsonContext,
          "language": AppStrings.languageCode, // Передаем текущий язык приложения
        },
      );
      return response.data['reply'];
    } catch (e) {
      return AppStrings.get('chat_error');
    }
  }
}