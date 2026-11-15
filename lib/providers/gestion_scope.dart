import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import 'collection_provider.dart';

class GestionScope {
  GestionScope(ApiClient client)
    : providers = {
        Modulo.productos: ProductosProvider(
          ApiGestionRepository(client, Modulo.productos),
        ),
        Modulo.categorias: CategoriasProvider(
          ApiGestionRepository(client, Modulo.categorias),
        ),
        Modulo.equipos: EquiposProvider(
          ApiGestionRepository(client, Modulo.equipos),
        ),
        Modulo.mantenimientos: MantenimientosProvider(
          ApiGestionRepository(client, Modulo.mantenimientos),
        ),
        Modulo.movimientos: MovimientosProvider(
          ApiGestionRepository(client, Modulo.movimientos),
        ),
      };
  final Map<Modulo, CollectionProvider> providers;
  CollectionProvider of(Modulo modulo) => providers[modulo]!;
  void limpiar() {
    for (final provider in providers.values) {
      provider.limpiar();
    }
  }

  Future<void> actualizarRelacionados(Modulo modulo) async {
    if (modulo == Modulo.movimientos) await of(Modulo.productos).cargar();
    if (modulo == Modulo.mantenimientos) await of(Modulo.equipos).cargar();
    if (modulo == Modulo.productos) await of(Modulo.categorias).cargar();
  }

  void dispose() {
    for (final provider in providers.values) {
      provider.dispose();
    }
  }
}
