import 'package:dio/dio.dart';
import '../main.dart'; // showDisplayError function ke liye

class ApiService {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://app.paisaloots.online',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) {
          String title = 'Network Alert';
          String detail = e.message ?? 'Server connect nahi ho paya.';

          if (e.response != null) {
            title = 'API Error (${e.response?.statusCode})';
            detail = e.response?.data?['message']?.toString() ?? e.response?.statusMessage ?? 'Server issue.';
          }
          showDisplayError(title, detail);
          return handler.next(e);
        },
      ),
    );
}

