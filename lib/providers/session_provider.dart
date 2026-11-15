import 'package:flutter/foundation.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';

class SessionProvider extends ChangeNotifier {
  SessionProvider(this.repository);
  final SessionRepository repository;
  Usuario? usuario;
  bool iniciando = true;
  bool ocupado = false;
  String? error;
  bool _disposed = false;
  int _version = 0;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> restaurar() async {
    final version = _version;
    try {
      final user = await repository.restaurar();
      if (version == _version) usuario = user;
    } catch (e) {
      error = mensajeError(e);
    }
    iniciando = false;
    _notify();
  }

  Future<bool> ingresar(String email, String password, {String? nombre}) async {
    if (ocupado) return false;
    ocupado = true;
    error = null;
    _notify();
    try {
      usuario = await repository.ingresar(email, password, nombre: nombre);
      return true;
    } catch (e) {
      error = mensajeError(e);
      return false;
    } finally {
      ocupado = false;
      _notify();
    }
  }

  Future<void> salir() async {
    _version++;
    usuario = null;
    iniciando = false;
    error = null;
    _notify();
    try {
      await repository.salir();
    } catch (_) {
      error =
          'No se pudo borrar la sesión guardada. Vuelve a intentar cerrar sesión.';
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
