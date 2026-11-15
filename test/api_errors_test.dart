import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_mantenimiento/data/repositories/repositories.dart';

void main() {
  for (final status in [400, 401, 403, 404, 409, 429]) {
    test(
      'el cliente transforma HTTP $status antes de salir del repositorio',
      () async {
        final client = ApiClient('https://example.invalid');
        addTearDown(client.dispose);
        final options = RequestOptions(path: '/productos');
        await expectLater(
          client.ejecutar<void>(() async {
            throw DioException(
              requestOptions: options,
              response: Response(requestOptions: options, statusCode: status),
              type: DioExceptionType.badResponse,
            );
          }),
          throwsA(
            isA<ApiException>().having((e) => e.message, 'mensaje', isNotEmpty),
          ),
        );
      },
    );
  }
  test('un conflicto conserva el mensaje de negocio del servidor', () {
    final options = RequestOptions(path: '/movimientos');
    expect(
      mensajeError(
        DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 409,
            data: {'message': 'Stock insuficiente. Disponible: 4.'},
          ),
        ),
      ),
      'Stock insuficiente. Disponible: 4.',
    );
  });
}
