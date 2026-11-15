import '../models/models.dart';
import 'api_client.dart';

abstract class GestionRepository {
  Future<Pagina> listar(Map<String, dynamic> filtros);
  Future<Registro> obtener(String id);
  Future<Registro> guardar(Map<String, dynamic> datos, {String? id});
  Future<void> eliminar(String id);
  Future<void> cerrar(String id);
}

class ApiGestionRepository implements GestionRepository {
  ApiGestionRepository(this.client, this.modulo);
  final ApiClient client;
  final Modulo modulo;
  String get path => '/${modulo.ruta}';
  @override
  Future<Pagina> listar(Map<String, dynamic> filtros) => client.ejecutar(
    () async => Pagina.fromJson(
      Map<String, dynamic>.from(
        (await client.dio.get(path, queryParameters: filtros)).data,
      ),
    ),
  );
  @override
  Future<Registro> obtener(String id) => client.ejecutar(
    () async => Registro(
      Map<String, dynamic>.from((await client.dio.get('$path/$id')).data),
    ),
  );
  @override
  Future<Registro> guardar(Map<String, dynamic> datos, {String? id}) =>
      client.ejecutar(() async {
        final response = id == null
            ? await client.dio.post(path, data: datos)
            : await client.dio.patch('$path/$id', data: datos);
        return Registro(Map<String, dynamic>.from(response.data));
      });

  @override
  Future<void> eliminar(String id) => client.ejecutar(() async {
    await client.dio.delete('$path/$id');
  });

  @override
  Future<void> cerrar(String id) => client.ejecutar(() async {
    await client.dio.patch('$path/$id/cerrar');
  });
}
