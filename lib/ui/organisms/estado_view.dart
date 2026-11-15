import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class EstadoView extends StatelessWidget {
  const EstadoView({
    super.key,
    required this.titulo,
    required this.mensaje,
    this.onRetry,
    this.icon = Icons.inbox_outlined,
  });
  final String titulo;
  final String mensaje;
  final VoidCallback? onRetry;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Spacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: Spacing.xxxl,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            titulo,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.sm),
          Text(mensaje, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: Spacing.lg),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ],
      ),
    ),
  );
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Cargando registros',
    child: Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        children: List.generate(
          4,
          (_) => Container(
            height: 90,
            margin: const EdgeInsets.only(bottom: Spacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(Radii.lg),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<bool> confirmar(
  BuildContext context,
  String titulo,
  String mensaje,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    ) ??
    false;
