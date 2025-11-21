import 'dart:io';
import 'package:dio/dio.dart';
import 'models.dart';

class ApiService {
  // Для Android Эмулятора адрес 10.0.2.2 обязателен!
  static const String _baseUrl = 'http://10.0.2.2:8000';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 60), // Ждем ответ до 60 сек
  ));

  Future<FinanceData> uploadStatement(File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      print("📤 Отправка файла на $_baseUrl/analyze...");

      Response response = await _dio.post(
        '$_baseUrl/analyze',
        data: formData,
      );

      print("✅ Ответ получен!");
      return FinanceData.fromJson(response.data);
    } catch (e) {
      print("❌ Ошибка соединения: $e");
      rethrow;
    }
  }
}