import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../data/models/models.dart';
import '../atoms/atoms.dart';

IconData iconoModulo(Modulo modulo) => switch (modulo) {
  Modulo.productos => Icons.inventory_2_outlined,
  Modulo.categorias => Icons.category_outlined,
  Modulo.equipos => Icons.precision_manufacturing_outlined,
  Modulo.mantenimientos => Icons.build_outlined,
  Modulo.movimientos => Icons.swap_vert,
};

String tituloRegistro(Registro item, Modulo modulo) => switch (modulo) {
  Modulo.mantenimientos => item.relacionado('equipo', 'nombre'),
  Modulo.movimientos => item.relacionado('producto', 'nombre'),
  _ => item.nombre,
};

String fechaCorta(String value) {
  final date = DateTime.tryParse(value)?.toLocal();
  return date == null
      ? ''
      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class RegistroCard extends StatelessWidget {
  const RegistroCard({
    super.key,
    required this.item,
    required this.modulo,
    required this.onTap,
  });
  final Registro item;
  final Modulo modulo;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = switch (modulo) {
      Modulo.productos => item.estadoStock,
      Modulo.equipos => item.enMantenimiento ? 'En mantenimiento' : 'Operativo',
      Modulo.mantenimientos =>
        item.texto('estado') == 'ABIERTO' ? 'Abierto' : 'Cerrado',
      Modulo.movimientos =>
        item.texto('tipo') == 'ENTRADA' ? 'Entrada' : 'Salida',
      Modulo.categorias =>
        '${(item.datos['_count'] as Map?)?['productos'] ?? 0} productos',
    };
    final subtitle = switch (modulo) {
      Modulo.productos =>
        '${item.codigo} · ${item.relacionado('categoria', 'nombre')}',
      Modulo.equipos => '${item.codigo} · ${item.texto('ubicacion')}',
      Modulo.mantenimientos =>
        '${item.texto('tipo') == 'PREVENTIVO' ? 'Preventivo' : 'Correctivo'} · ${fechaCorta(item.texto('fecha'))}',
      Modulo.movimientos =>
        '${fechaCorta(item.texto('fecha'))} · ${item.relacionado('usuario', 'nombre')}',
      Modulo.categorias => item.texto('descripcion'),
    };
    if (modulo == Modulo.productos) {
      return Card(
        margin: const EdgeInsets.only(bottom: Spacing.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.md),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: cs.primaryContainer,
                      foregroundColor: cs.onPrimaryContainer,
                      child: const Icon(Icons.inventory_2),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.nombre,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    StatusBadge(
                      label: label,
                      tono: label == 'Agotado'
                          ? BadgeTono.error
                          : label == 'Stock bajo'
                          ? BadgeTono.terciario
                          : BadgeTono.primario,
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stock: ${item.stock} ${item.texto('unidad')}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '\$ ${(double.tryParse(item.texto('precio')) ?? 0).toStringAsFixed(2)}',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: cs.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: cs.primaryContainer,
                foregroundColor: cs.onPrimaryContainer,
                child: Icon(iconoModulo(modulo)),
              ),
              const SizedBox(width: Spacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tituloRegistro(item, modulo),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: Spacing.xs),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: Spacing.sm),
                    Wrap(
                      spacing: Spacing.sm,
                      runSpacing: Spacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusBadge(
                          label: label,
                          tono: label == 'Agotado' || label == 'Stock bajo'
                              ? BadgeTono.error
                              : BadgeTono.primario,
                        ),
                        if (modulo == Modulo.productos)
                          Text('${item.stock} ${item.texto('unidad')}'),
                        if (modulo == Modulo.movimientos)
                          Text(
                            '${item.texto('tipo') == 'ENTRADA' ? '+' : '−'}${item.entero('cantidad')}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
