import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_mantenimiento/data/models/registro.dart';
import 'package:app_mantenimiento/data/repositories/gestion_repository.dart';
import 'package:app_mantenimiento/data/repositories/session_repository.dart';
import 'package:app_mantenimiento/data/repositories/api_client.dart';
import 'package:app_mantenimiento/providers/collection_provider.dart';
import 'package:app_mantenimiento/providers/session_provider.dart';

class FakeRepository implements GestionRepository {
  final calls = <Map<String, dynamic>>[];
  Completer<Pagina>? pending;
  bool fail = false;
  bool conflict = false;
  @override
  Future<Pagina> listar(Map<String, dynamic> filtros) async {
    calls.add(filtros);
    if (fail) throw const ApiException('Sin conexión');
    if (pending != null) return pending!.future;
    return Pagina(
      [
        Registro({
          'id': '1',
          'nombre': 'Rodamiento',
          'stock': 3,
          'stockMinimo': 5,
        }),
      ],
      1,
      1,
    );
  }

  @override
  Future<Registro> guardar(Map<String, dynamic> datos, {String? id}) async {
    if (conflict) throw const ApiException('Stock insuficiente');
    return Registro({'id': id ?? '2', ...datos});
  }

  @override
  Future<Registro> obtener(String id) async => Registro({'id': id});
  @override
  Future<void> eliminar(String id) async {}
  @override
  Future<void> cerrar(String id) async {}
}

class FakeSession implements SessionRepository {
  bool fail = false;
  bool closed = false;
  @override
  Future<Usuario?> restaurar() async => null;
  @override
  Future<Usuario> ingresar(
    String email,
    String password, {
    String? nombre,
  }) async {
    if (fail) throw const ApiException('Credenciales incorrectas');
    return Usuario(nombre: 'Ana', email: email, rol: 'BODEGUERO');
  }

  @override
  Future<void> salir() async {
    closed = true;
  }
}

void main() {
  test('expone carga antes de recibir datos', () async {
    final repo = FakeRepository()..pending = Completer<Pagina>();
    final p = ProductosProvider(repo);
    final load = p.cargar();
    expect(p.cargando, true);
    repo.pending!.complete(const Pagina([], 0, 0));
    await load;
    expect(p.cargando, false);
    expect(p.registros, isEmpty);
    p.dispose();
  });
  test('transmite filtros y reinicia la paginación', () async {
    final repo = FakeRepository();
    final p = ProductosProvider(repo);
    await p.cargar(page: 3);
    await p.cargar(filtros: {'search': 'rod', 'categoriaId': 'cat'});
    expect(repo.calls.last, {
      'page': 1,
      'limit': 20,
      'search': 'rod',
      'categoriaId': 'cat',
    });
    p.dispose();
  });
  test('permite reintentar después de un error', () async {
    final repo = FakeRepository()..fail = true;
    final p = ProductosProvider(repo);
    await p.cargar();
    expect(p.error, 'Sin conexión');
    repo.fail = false;
    await p.cargar();
    expect(p.error, isNull);
    expect(p.registros.single.nombre, 'Rodamiento');
    p.dispose();
  });
  test('no cambia datos si el servidor rechaza un movimiento', () async {
    final repo = FakeRepository()..conflict = true;
    final p = MovimientosProvider(repo);
    expect(await p.guardar({'cantidad': 10}), false);
    expect(p.error, 'Stock insuficiente');
    expect(repo.calls, isEmpty);
    expect(p.guardando, false);
    p.dispose();
  });
  test('guardar recarga la lista', () async {
    final repo = FakeRepository();
    final p = CategoriasProvider(repo);
    expect(await p.guardar({'nombre': 'Repuestos'}), true);
    expect(repo.calls.length, 1);
    p.dispose();
  });
  test('descarta resultados de solicitudes anteriores', () async {
    final repo = FakeRepository()..pending = Completer<Pagina>();
    final p = EquiposProvider(repo);
    final pending = repo.pending!;
    final old = p.cargar();
    repo.pending = null;
    await p.cargar(filtros: {'search': 'nuevo'});
    pending.complete(const Pagina([], 0, 0));
    await old;
    expect(p.registros, hasLength(1));
    p.dispose();
  });
  test('no notifica ni aplica datos después de dispose', () async {
    final repo = FakeRepository()..pending = Completer<Pagina>();
    final p = EquiposProvider(repo);
    var count = 0;
    p.addListener(() => count++);
    final request = p.cargar();
    p.dispose();
    repo.pending!.complete(const Pagina([], 0, 0));
    await request;
    expect(count, 1);
  });
  test('la sesión conserva el rol y se elimina al salir', () async {
    final repo = FakeSession();
    final p = SessionProvider(repo);
    await p.restaurar();
    expect(p.iniciando, false);
    await p.ingresar('ana@example.com', 'password123');
    expect(p.usuario!.esAdmin, false);
    await p.salir();
    expect(p.usuario, isNull);
    expect(repo.closed, true);
    p.dispose();
  });
  test('login fallido no crea una sesión', () async {
    final repo = FakeSession()..fail = true;
    final p = SessionProvider(repo);
    expect(await p.ingresar('ana@example.com', 'password123'), false);
    expect(p.usuario, isNull);
    expect(p.error, 'Credenciales incorrectas');
    p.dispose();
  });
  test('estado del stock utiliza el mínimo configurado', () {
    expect(Registro({'stock': 0, 'stockMinimo': 5}).estadoStock, 'Agotado');
    expect(Registro({'stock': 3, 'stockMinimo': 5}).estadoStock, 'Stock bajo');
    expect(Registro({'stock': 5, 'stockMinimo': 5}).estadoStock, 'Disponible');
  });
}
