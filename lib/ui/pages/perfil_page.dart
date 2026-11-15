import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../providers/providers.dart';
import '../organisms/organisms.dart';

class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});
  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionProvider>().usuario;
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: ListView(
            padding: const EdgeInsets.all(Spacing.xl),
            children: [
              const CircleAvatar(
                radius: Spacing.xxxl,
                child: Icon(Icons.person_outline, size: Spacing.xxxl),
              ),
              const SizedBox(height: Spacing.xl),
              Text(
                user?.nombre ?? '',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(user?.email ?? '', textAlign: TextAlign.center),
              const SizedBox(height: Spacing.lg),
              Text(
                user?.esAdmin == true
                    ? 'Administrador · gestión completa'
                    : 'Bodeguero · consultas y movimientos',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.xxl),
              DropdownButtonFormField<ThemeMode>(
                initialValue: context.watch<ThemeProvider>().mode,
                decoration: const InputDecoration(labelText: 'Apariencia'),
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('Según el dispositivo'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text('Claro'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text('Oscuro'),
                  ),
                ],
                onChanged: (mode) {
                  if (mode != null) context.read<ThemeProvider>().cambiar(mode);
                },
              ),
              const SizedBox(height: Spacing.xl),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.category_outlined),
                      title: const Text('Categorías'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/categorias'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.palette_outlined),
                      title: const Text('Galería de componentes'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/galeria'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.xl),
              OutlinedButton.icon(
                onPressed: () async {
                  final session = context.read<SessionProvider>();
                  if (await confirmar(
                    context,
                    'Cerrar sesión',
                    'Tendrás que iniciar sesión para volver a entrar.',
                  )) {
                    await session.salir();
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
