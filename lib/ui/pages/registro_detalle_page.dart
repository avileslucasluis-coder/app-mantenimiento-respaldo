import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../providers/providers.dart';
import '../organisms/organisms.dart';

class RegistroDetallePage extends StatefulWidget {
  const RegistroDetallePage({
    super.key,
    required this.modulo,
    required this.id,
  });
  final Modulo modulo;
  final String id;
  @override
  State<RegistroDetallePage> createState() => _RegistroDetallePageState();
}

class _RegistroDetallePageState extends State<RegistroDetallePage> {
  late Future<Registro> _future;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context
        .read<GestionScope>()
        .of(widget.modulo)
        .repository
        .obtener(widget.id);
  }

  Future<void> _action(bool cerrar) async {
    if (!await confirmar(
      context,
      cerrar ? 'Cerrar orden' : 'Eliminar registro',
      cerrar
          ? 'La orden cerrada ya no admitirá salidas de repuestos.'
          : 'El registro se eliminará si no tiene historial ni datos relacionados.',
    )) {
      return;
    }
    if (!mounted) return;
    setState(() => _busy = true);
    final scope = context.read<GestionScope>();
    final provider = scope.of(widget.modulo);
    final ok = cerrar
        ? await provider.cerrar(widget.id)
        : await provider.eliminar(widget.id);
    await scope.actualizarRelacionados(widget.modulo);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'No se pudo completar la operación.'),
        ),
      );
      return;
    }
    if (cerrar) {
      setState(_load);
    } else {
      context.go('/${widget.modulo.ruta}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<SessionProvider>().usuario?.esAdmin ?? false;
    final modulo = widget.modulo;
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de ${modulo.singular.toLowerCase()}'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () => setState(_load),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Registro>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return EstadoView(
              titulo: 'No se pudo cargar',
              mensaje: mensajeError(snapshot.error!),
              onRetry: () => setState(_load),
            );
          }
          if (!snapshot.hasData) return const SkeletonCard();
          final item = snapshot.data!;
          final fields = <String, String>{
            if (item.codigo.isNotEmpty) 'Código': item.codigo,
            if (item.texto('descripcion').isNotEmpty)
              'Descripción': item.texto('descripcion'),
            if (modulo == Modulo.productos) ...{
              'Categoría': item.relacionado('categoria', 'nombre'),
              'Stock':
                  '${item.stock} ${item.texto('unidad')} · ${item.estadoStock}',
              'Stock mínimo': item.texto('stockMinimo'),
              'Precio unitario': '\$${item.texto('precio')}',
            },
            if (modulo == Modulo.equipos) ...{
              'Ubicación': item.texto('ubicacion'),
              'Estado': item.enMantenimiento ? 'En mantenimiento' : 'Operativo',
            },
            if (!modulo.maestro) ...{
              'Tipo': item.texto('tipo'),
              'Fecha': fechaCorta(item.texto('fecha')),
            },
            if (modulo == Modulo.mantenimientos) ...{
              'Estado': item.texto('estado'),
              if (item.texto('cerradoEn').isNotEmpty)
                'Cierre': fechaCorta(item.texto('cerradoEn')),
            },
            if (modulo == Modulo.movimientos) ...{
              'Cantidad': item.texto('cantidad'),
              'Motivo': item.texto('motivo'),
              'Registrado por': item.relacionado('usuario', 'nombre'),
              if (item.texto('mantenimientoId').isNotEmpty)
                'Orden de mantenimiento': item.texto('mantenimientoId'),
            },
          };
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: const EdgeInsets.all(Spacing.xl),
                children: [
                  Icon(
                    iconoModulo(modulo),
                    size: Spacing.xxxl,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: Spacing.lg),
                  Text(
                    tituloRegistro(item, modulo),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: Spacing.xl),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final entry in fields.entries)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: Spacing.lg,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelMedium,
                                  ),
                                  const SizedBox(height: Spacing.xs),
                                  SelectableText(entry.value),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),
                  Wrap(
                    spacing: Spacing.md,
                    runSpacing: Spacing.sm,
                    children: [
                      if (admin && modulo.maestro) ...[
                        FilledButton.icon(
                          onPressed: _busy
                              ? null
                              : () async {
                                  await context.push(
                                    '/${modulo.ruta}/${item.id}/editar',
                                  );
                                  if (mounted) setState(_load);
                                },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Editar'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : () => _action(false),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Eliminar'),
                        ),
                      ],
                      if (modulo == Modulo.mantenimientos &&
                          item.texto('estado') == 'ABIERTO') ...[
                        FilledButton.icon(
                          onPressed: _busy
                              ? null
                              : () async {
                                  await context.push(
                                    '/movimientos/nuevo?orden=${item.id}',
                                  );
                                  if (mounted) setState(_load);
                                },
                          icon: const Icon(Icons.inventory_2_outlined),
                          label: const Text('Usar repuestos'),
                        ),
                        if (admin)
                          OutlinedButton.icon(
                            onPressed: _busy ? null : () => _action(true),
                            icon: const Icon(Icons.task_alt),
                            label: const Text('Cerrar orden'),
                          ),
                      ],
                      if (modulo == Modulo.productos ||
                          modulo == Modulo.equipos)
                        OutlinedButton.icon(
                          onPressed: () {
                            final target = modulo == Modulo.productos
                                ? Modulo.movimientos
                                : Modulo.mantenimientos;
                            context.read<GestionScope>().of(target).filtros = {
                              modulo == Modulo.productos
                                      ? 'productoId'
                                      : 'equipoId':
                                  item.id,
                            };
                            context.go('/${target.ruta}');
                          },
                          icon: const Icon(Icons.history),
                          label: const Text('Ver historial'),
                        ),
                    ],
                  ),
                  if (modulo == Modulo.mantenimientos) ...[
                    const SizedBox(height: Spacing.xxl),
                    Text(
                      'Repuestos utilizados',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: Spacing.md),
                    if ((item.datos['movimientos'] as List? ?? []).isEmpty)
                      const Text(
                        'Esta orden aún no tiene consumo de repuestos.',
                      ),
                    for (final raw in item.datos['movimientos'] as List? ?? [])
                      ListTile(
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: Text(raw['producto']['nombre'] as String),
                        trailing: Text('${raw['cantidad']}'),
                        onTap: () => context.push('/movimientos/${raw['id']}'),
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
