import 'package:flutter/foundation.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';

class CollectionProvider extends ChangeNotifier {
  CollectionProvider(this.repository);
  final GestionRepository repository;
  List<Registro> registros = [];
  Map<String, dynamic> filtros = {};
  int pagina = 1;
  int total = 0;
  int paginas = 0;
  bool cargando = false;
  bool guardando = false;
  String? error;
  bool _disposed = false;
  int _request = 0;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> cargar({int? page, Map<String, dynamic>? filtros}) async {
    if (_disposed) return;
    if (filtros != null) {
      this.filtros = filtros;
      pagina = 1;
    }
    pagina = page ?? pagina;
    final request = ++_request;
    cargando = true;
    error = null;
    _notify();
    try {
      final result = await repository.listar({
        ...this.filtros,
        'page': pagina,
        'limit': 20,
      });
      if (_disposed || request != _request) return;
      registros = result.registros;
      total = result.total;
      paginas = result.paginas;
    } catch (e) {
      if (request == _request) error = mensajeError(e);
    } finally {
      if (request == _request) {
        cargando = false;
        _notify();
      }
    }
  }

  Future<bool> guardar(Map<String, dynamic> datos, {String? id}) =>
      _mutar(() async {
        await repository.guardar(datos, id: id);
      });
  Future<bool> eliminar(String id) => _mutar(() => repository.eliminar(id));
  Future<bool> cerrar(String id) => _mutar(() => repository.cerrar(id));
  Future<bool> _mutar(Future<void> Function() operation) async {
    if (_disposed || guardando) return false;
    guardando = true;
    error = null;
    _notify();
    try {
      await operation();
      await cargar(page: 1);
      return true;
    } catch (e) {
      error = mensajeError(e);
      return false;
    } finally {
      guardando = false;
      _notify();
    }
  }

  void limpiar() {
    ++_request;
    registros = [];
    filtros = {};
    pagina = 1;
    total = 0;
    paginas = 0;
    error = null;
    cargando = false;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_request;
    super.dispose();
  }
}

class ProductosProvider extends CollectionProvider {
  ProductosProvider(super.repository);
}

class CategoriasProvider extends CollectionProvider {
  CategoriasProvider(super.repository);
}

class EquiposProvider extends CollectionProvider {
  EquiposProvider(super.repository);
}

class MantenimientosProvider extends CollectionProvider {
  MantenimientosProvider(super.repository);
}

class MovimientosProvider extends CollectionProvider {
  MovimientosProvider(super.repository);
}
