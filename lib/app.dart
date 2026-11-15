import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme.dart';
import 'data/models/models.dart';
import 'data/repositories/repositories.dart';
import 'providers/providers.dart';
import 'ui/organisms/organisms.dart';
import 'ui/pages/pages.dart';
import 'ui/templates/templates.dart';

class App extends StatefulWidget {
  const App({super.key, this.sessionRepository, this.apiUrl});
  final SessionRepository? sessionRepository;
  final String? apiUrl;
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final ApiClient _api;
  late final SessionProvider _session;
  late final GestionScope _scope;
  late final GoRouter _router;
  late final bool _configured;
  final ThemeProvider _theme = ThemeProvider();
  bool _hadSession = false;
  @override
  void initState() {
    super.initState();
    final url = widget.apiUrl ?? const String.fromEnvironment('API_URL');
    final uri = Uri.tryParse(url);
    _configured =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    _api = ApiClient(_configured ? url : '');
    _session = SessionProvider(
      widget.sessionRepository ??
          ApiSessionRepository(_api, const FlutterSecureStorage()),
    );
    _scope = GestionScope(_api);
    _api.onUnauthorized = _session.salir;
    _session.addListener(_onSession);
    _router = GoRouter(
      initialLocation: '/productos',
      refreshListenable: _session,
      redirect: (context, state) {
        if (!_configured) {
          return state.matchedLocation == '/configuracion'
              ? null
              : '/configuracion';
        }
        if (_session.iniciando) {
          return state.matchedLocation == '/cargando' ? null : '/cargando';
        }
        final authPage =
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/registro';
        if (_session.usuario == null) return authPage ? null : '/login';
        if (authPage || state.matchedLocation == '/cargando') {
          return '/productos';
        }
        if (!_session.usuario!.esAdmin &&
            (state.matchedLocation.endsWith('/editar') ||
                (state.matchedLocation.endsWith('/nuevo') &&
                    !state.matchedLocation.startsWith('/movimientos')))) {
          return '/productos';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/configuracion',
          builder: (_, _) => const Scaffold(
            body: EstadoView(
              titulo: 'Configura la conexión',
              mensaje:
                  'Inicia la aplicación con --dart-define=API_URL seguido de la dirección de tu API. Consulta el README para los comandos completos.',
            ),
          ),
        ),
        GoRoute(
          path: '/cargando',
          builder: (_, _) =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
        ),
        GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
        GoRoute(
          path: '/registro',
          builder: (_, _) => const LoginPage(registro: true),
        ),
        GoRoute(path: '/galeria', builder: (_, _) => const GaleriaPage()),
        ShellRoute(
          builder: (context, state, child) =>
              AppShell(location: state.uri.path, child: child),
          routes: [
            for (final modulo in Modulo.values)
              GoRoute(
                path: '/${modulo.ruta}',
                builder: (_, _) =>
                    ColeccionPage(key: ValueKey(modulo), modulo: modulo),
              ),
            GoRoute(path: '/perfil', builder: (_, _) => const PerfilPage()),
          ],
        ),
        for (final modulo in Modulo.values) ...[
          GoRoute(
            path: '/${modulo.ruta}/nuevo',
            builder: (_, state) => RegistroFormPage(
              modulo: modulo,
              ordenId: state.uri.queryParameters['orden'],
            ),
          ),
          if (modulo.maestro)
            GoRoute(
              path: '/${modulo.ruta}/:id/editar',
              builder: (_, state) => RegistroFormPage(
                modulo: modulo,
                id: state.pathParameters['id']!,
              ),
            ),
          GoRoute(
            path: '/${modulo.ruta}/:id',
            builder: (_, state) => RegistroDetallePage(
              modulo: modulo,
              id: state.pathParameters['id']!,
            ),
          ),
        ],
      ],
      errorBuilder: (_, _) => const Scaffold(
        body: EstadoView(
          titulo: 'Página no encontrada',
          mensaje: 'Comprueba la dirección o vuelve a la pantalla anterior.',
        ),
      ),
    );
    if (_configured) _session.restaurar();
  }

  void _onSession() {
    if (_hadSession && _session.usuario == null) _scope.limpiar();
    _hadSession = _session.usuario != null;
  }

  @override
  void dispose() {
    _router.dispose();
    _session.removeListener(_onSession);
    _session.dispose();
    _scope.dispose();
    _api.dispose();
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: _session),
      Provider.value(value: _scope),
      ChangeNotifierProvider.value(value: _theme),
      ChangeNotifierProvider.value(
        value: _scope.of(Modulo.productos) as ProductosProvider,
      ),
      ChangeNotifierProvider.value(
        value: _scope.of(Modulo.categorias) as CategoriasProvider,
      ),
      ChangeNotifierProvider.value(
        value: _scope.of(Modulo.equipos) as EquiposProvider,
      ),
      ChangeNotifierProvider.value(
        value: _scope.of(Modulo.mantenimientos) as MantenimientosProvider,
      ),
      ChangeNotifierProvider.value(
        value: _scope.of(Modulo.movimientos) as MovimientosProvider,
      ),
    ],
    child: Consumer<ThemeProvider>(
      builder: (context, appearance, _) => MaterialApp.router(
        title: 'Gestión integral',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: appearance.mode,
        routerConfig: _router,
        builder: (context, child) => AnimatedBuilder(
          animation: _router.routeInformationProvider,
          builder: (context, _) {
            final path = _router.routeInformationProvider.value.uri.path;
            final mantenimiento =
                path.startsWith('/equipos') ||
                path.startsWith('/mantenimientos') ||
                path == '/galeria';
            return Theme(
              data: AppTheme.build(
                Theme.of(context).brightness,
                mantenimiento: mantenimiento,
              ),
              child: child!,
            );
          },
        ),
      ),
    ),
  );
}
