import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

String mensajeError(Object error) {
  if (error is ApiException) return error.message;
  if (error is! DioException) {
    return 'No se pudo completar la operación. Inténtalo de nuevo.';
  }
  final status = error.response?.statusCode;
  final body = error.response?.data;
  if ([400, 404, 409].contains(status) &&
      body is Map &&
      body['message'] is String) {
    return body['message'] as String;
  }
  return switch (status) {
    400 => 'Revisa los campos. Hay datos inválidos o incompletos.',
    401 => 'Correo o contraseña incorrectos, o sesión vencida.',
    403 => 'No tienes permiso para realizar esta acción.',
    404 => 'No se encontró el registro.',
    409 => 'No se puede guardar: existe un conflicto con los datos.',
    429 => 'Demasiados intentos. Espera un minuto y vuelve a intentarlo.',
    _ =>
      error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout
          ? 'No se pudo conectar con el servidor. Revisa la conexión y reintenta.'
          : 'El servidor no pudo completar la operación.',
  };
}

class ApiClient {
  ApiClient(String baseUrl)
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 90),
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 30),
          headers: {'Accept': 'application/json'},
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/auth/login')) {
            token = null;
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }
  final Dio dio;
  String? token;
  void Function()? onUnauthorized;
  Future<T> ejecutar<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on DioException catch (error) {
      throw ApiException(mensajeError(error));
    }
  }

  void dispose() => dio.close(force: true);
}
