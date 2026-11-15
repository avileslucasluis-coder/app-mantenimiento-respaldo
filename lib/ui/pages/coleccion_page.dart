import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../organisms/organisms.dart';

class ColeccionPage extends StatefulWidget {
  const ColeccionPage({super.key, required this.modulo});
  final Modulo modulo;
  @override
  State<ColeccionPage> createState() => _ColeccionPageState();
}

class _ColeccionPageState extends State<ColeccionPage> {
  Timer? _debounce;
  late CollectionProvider provider;
  late TextEditingController _search;
  @override
  void initState() {
    super.initState();
    provider = context.read<GestionScope>().of(widget.modulo);
    _search = TextEditingController(
      text: provider.filtros['search'] as String? ?? '',
    );
    Future.microtask(() => provider.cargar());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _filter(String key, String? value) {
    final filters = {...provider.filtros};
    if (value == null || value.isEmpty) {
      filters.remove(key);
    } else {
      filters[key] = value;
    }
    provider.cargar(filtros: filters);
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: provider,
    child: Consumer<CollectionProvider>(
      builder: (context, p, _) {
        final modulo = widget.modulo;
        final admin =
            context.watch<SessionProvider>().usuario?.esAdmin ?? false;
        final canAdd = admin || modulo == Modulo.movimientos;
        return Scaffold(
          appBar: AppBar(
            title: Text(modulo.titulo),
            actions: [
              if (modulo == Modulo.productos)
                IconButton(
                  tooltip: 'Categorías',
                  onPressed: () => context.push('/categorias'),
                  icon: const Icon(Icons.category_outlined),
                ),
              IconButton(
                tooltip: 'Actualizar',
                onPressed: p.cargando ? null : () => p.cargar(),
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: 'Mi perfil',
                onPressed: () => context.go('/perfil'),
                icon: const Icon(Icons.account_circle_outlined),
              ),
            ],
          ),
          floatingActionButton: canAdd
              ? FloatingActionButton.extended(
                  onPressed: () => context.push('/${modulo.ruta}/nuevo'),
                  icon: const Icon(Icons.add),
                  label: Text(
                    modulo == Modulo.movimientos ? 'Registrar' : 'Agregar',
                  ),
                )
              : null,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.lg,
                      Spacing.md,
                      Spacing.lg,
                      Spacing.sm,
                    ),
                    child: TextField(
                      controller: _search,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: modulo == Modulo.movimientos
                            ? 'Buscar por motivo'
                            : modulo == Modulo.mantenimientos
                            ? 'Buscar por descripción'
                            : 'Buscar por nombre o código',
                      ),
                      onChanged: (value) {
                        _debounce?.cancel();
                        _debounce = Timer(
                          const Duration(milliseconds: 350),
                          () => _filter('search', value.trim()),
                        );
                      },
                    ),
                  ),
                  if (modulo == Modulo.movimientos ||
                      modulo == Modulo.mantenimientos)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.lg,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: Spacing.sm,
                          children: [
                            for (final entry
                                in (modulo == Modulo.movimientos
                                        ? {
                                            '': 'Todos',
                                            'ENTRADA': 'Entradas',
                                            'SALIDA': 'Salidas',
                                          }
                                        : {
                                            '': 'Todas',
                                            'ABIERTO': 'Abiertas',
                                            'CERRADO': 'Cerradas',
                                          })
                                    .entries)
                              ChoiceChip(
                                label: Text(entry.value),
                                selected:
                                    (p.filtros[modulo == Modulo.movimientos
                                            ? 'tipo'
                                            : 'estado'] ??
                                        '') ==
                                    entry.key,
                                onSelected: (_) => _filter(
                                  modulo == Modulo.movimientos
                                      ? 'tipo'
                                      : 'estado',
                                  entry.key,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (modulo == Modulo.productos ||
                      modulo == Modulo.movimientos)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.lg,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () async {
                            final reference = modulo == Modulo.productos
                                ? Modulo.categorias
                                : Modulo.productos;
                            final id = await showDialog<String>(
                              context: context,
                              builder: (_) =>
                                  SelectorRegistros(modulo: reference),
                            );
                            if (id != null && mounted) {
                              _filter(
                                modulo == Modulo.productos
                                    ? 'categoriaId'
                                    : 'productoId',
                                id,
                              );
                            }
                          },
                          icon: const Icon(Icons.filter_list),
                          label: Text(
                            p.filtros.containsKey(
                                  modulo == Modulo.productos
                                      ? 'categoriaId'
                                      : 'productoId',
                                )
                                ? 'Filtro activo · cambiar'
                                : modulo == Modulo.productos
                                ? 'Filtrar por categoría'
                                : 'Filtrar por producto',
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.lg,
                      vertical: Spacing.sm,
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${p.total} registros',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const Spacer(),
                        if (p.paginas > 1) ...[
                          IconButton(
                            tooltip: 'Página anterior',
                            onPressed: p.pagina > 1 && !p.cargando
                                ? () => p.cargar(page: p.pagina - 1)
                                : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text('${p.pagina} / ${p.paginas}'),
                          IconButton(
                            tooltip: 'Página siguiente',
                            onPressed: p.pagina < p.paginas && !p.cargando
                                ? () => p.cargar(page: p.pagina + 1)
                                : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: p.cargando
                        ? const SkeletonCard()
                        : p.error != null
                        ? EstadoView(
                            titulo: 'No se pudieron cargar los datos',
                            mensaje: p.error!,
                            onRetry: () => p.cargar(),
                            icon: Icons.cloud_off_outlined,
                          )
                        : p.registros.isEmpty
                        ? EstadoView(
                            titulo: 'Sin registros',
                            mensaje: p.filtros.isEmpty
                                ? 'Los registros aparecerán aquí cuando se agreguen.'
                                : 'No hay resultados para estos filtros.',
                          )
                        : RefreshIndicator(
                            onRefresh: () => p.cargar(),
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                Spacing.lg,
                                0,
                                Spacing.lg,
                                100,
                              ),
                              itemCount: p.registros.length,
                              itemBuilder: (context, index) => RegistroCard(
                                item: p.registros[index],
                                modulo: modulo,
                                onTap: () => context.push(
                                  '/${modulo.ruta}/${p.registros[index].id}',
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class SelectorRegistros extends StatefulWidget {
  const SelectorRegistros({super.key, required this.modulo});
  final Modulo modulo;
  @override
  State<SelectorRegistros> createState() => SelectorRegistrosState();
}

class SelectorRegistrosState extends State<SelectorRegistros> {
  late Future<Pagina> _future;
  int _page = 1;
  String _search = '';
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<GestionScope>().of(widget.modulo).repository.listar({
      'page': _page,
      'limit': 20,
      'search': _search,
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.modulo.titulo),
    content: SizedBox(
      width: 450,
      height: 400,
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Buscar',
              suffixIcon: Icon(Icons.search),
            ),
            onSubmitted: (v) => setState(() {
              _search = v;
              _page = 1;
              _load();
            }),
          ),
          Expanded(
            child: FutureBuilder<Pagina>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return EstadoView(
                    titulo: 'No se pudo cargar',
                    mensaje: 'Vuelve a intentarlo.',
                    onRetry: () => setState(_load),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final page = snapshot.data!;
                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          for (final item in page.registros)
                            ListTile(
                              title: Text(item.nombre),
                              subtitle: item.codigo.isEmpty
                                  ? null
                                  : Text(item.codigo),
                              onTap: () => Navigator.pop(context, item.id),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: _page > 1
                              ? () => setState(() {
                                  _page--;
                                  _load();
                                })
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text(
                          '$_page / ${page.paginas == 0 ? 1 : page.paginas}',
                        ),
                        IconButton(
                          onPressed: _page < page.paginas
                              ? () => setState(() {
                                  _page++;
                                  _load();
                                })
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, ''),
        child: const Text('Quitar filtro'),
      ),
    ],
  );
}
