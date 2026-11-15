import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';
import 'api_client.dart';

abstract class SessionRepository {
  Future<Usuario?> restaurar();
  Future<Usuario> ingresar(String email, String password, {String? nombre});
  Future<void> salir();
}

class ApiSessionRepository implements SessionRepository {
  ApiSessionRepository(this.client, this.storage);
  final ApiClient client;
  final FlutterSecureStorage storage;
  static const tokenKey = 'gestion.access_token';
  @override
  Future<Usuario?> restaurar() => client.ejecutar(() async {
    client.token = await storage.read(key: tokenKey);
    if (client.token == null) return null;
    return Usuario.fromJson(
      Map<String, dynamic>.from((await client.dio.get('/auth/me')).data),
    );
  });

  @override
  Future<Usuario> ingresar(String email, String password, {String? nombre}) =>
      client.ejecutar(() async {
        final response = await client.dio.post(
          nombre == null ? '/auth/login' : '/auth/register',
          data: {
            'email': email.trim(),
            'password': password,
            if (nombre != null) 'nombre': nombre.trim(),
          },
        );
        final token = response.data['accessToken'] as String;
        await storage.write(key: tokenKey, value: token);
        client.token = token;
        return Usuario.fromJson(
          Map<String, dynamic>.from(response.data['user']),
        );
      });

  @override
  Future<void> salir() async {
    client.token = null;
    await storage.delete(key: tokenKey);
  }
}
