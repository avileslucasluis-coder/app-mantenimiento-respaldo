# Gestión integral: inventario y mantenimiento

Aplicación Flutter para administrar productos, equipos y órdenes de mantenimiento desde una misma sesión. La API NestJS está en `C:\ejercicio en clase\api-mantenimiento` y persiste los datos con Prisma y PostgreSQL.

## Qué puedes hacer

- Crear categorías, productos y equipos como administrador.
- Registrar entradas y salidas de inventario como administrador o bodeguero.
- Abrir órdenes preventivas o correctivas para un equipo.
- Desde una orden abierta, usar repuestos: la salida descuenta stock y queda vinculada al mantenimiento.
- Consultar historial, buscar, filtrar y recorrer listas paginadas.
- Cerrar una orden. El equipo vuelve a operativo cuando no tiene órdenes abiertas.

El stock no se modifica desde el formulario de producto. Una salida mayor al disponible se rechaza sin guardar un movimiento parcial. Los movimientos son históricos: no se editan ni eliminan.

## Requisitos

- Flutter 3.44.4 o compatible con Dart 3.12 o superior.
- Node.js 24.15 o superior recomendado para las herramientas actuales de NestJS.
- Docker Desktop para la base local, o PostgreSQL/Supabase configurado.
- Chrome para web; Android Studio y un dispositivo o emulador para Android.

## 1. Iniciar la API

En PowerShell:

```powershell
cd 'C:\ejercicio en clase\api-mantenimiento'
npm ci
# Solo si aún no tienes .env:
Copy-Item .env.example .env
```

Edita `.env`: cambia `DB_PASSWORD`, usa esa misma contraseña en `DATABASE_URL`, establece un `JWT_SECRET` aleatorio de al menos 32 caracteres y configura `ADMIN_EMAIL` y `ADMIN_PASSWORD` (mínimo 10 caracteres). No publiques este archivo.

En este equipo ya se creó un `.env` local con valores aleatorios. No lo sobrescribas: consulta allí las credenciales del administrador.

```powershell
docker compose up -d
npm run db:generate
npm run db:migrate
npm run build
npm run start:prod
```

- Estado: http://localhost:3000/health
- Documentación: http://localhost:3000/docs
- PostgreSQL local: puerto 5544. No utiliza las bases de otros proyectos.

El administrador se crea al iniciar la API. Si ya existe, cambiar `ADMIN_PASSWORD` no modifica su contraseña automáticamente. El registro público siempre crea un BODEGUERO.

## 2. Ejecutar la app

En otra terminal:

```powershell
cd C:\app-mantenimiento
flutter pub get
flutter run -d chrome --web-port=5173 --dart-define=API_URL=http://localhost:3000
```

Usa `localhost`, no `127.0.0.1`, en el navegador para coincidir con `CORS_ORIGINS`. La URL de la API se define al compilar; no contiene credenciales. Si falta, la app muestra una pantalla de configuración.

Para un emulador Android:

```powershell
flutter run --dart-define=API_URL=http://10.0.2.2:3000
```

Para un teléfono físico, sustituye la URL por la IP LAN del computador y usa la misma red. El HTTP local está habilitado solo en la variante debug; para una versión distribuible usa una API HTTPS.

## 3. Primer recorrido

1. Inicia sesión con el administrador configurado en `.env`.
2. En Inventario, abre Categorías y crea una categoría, por ejemplo Repuestos.
3. Crea un producto con código, nombre, categoría, precio, unidad y stock mínimo. Empieza con stock cero.
4. En Actividad, registra una Entrada para ese producto.
5. En Equipos, crea un equipo indicando código, nombre y ubicación.
6. En Órdenes, crea un mantenimiento y selecciona el equipo.
7. Abre la orden y pulsa Usar repuestos. Selecciona el producto y la cantidad; la orden ya está vinculada.
8. Consulta el stock actualizado en Inventario y los repuestos usados en el detalle de la orden.
9. Cierra la orden cuando termine el trabajo.
10. Prueba con una cuenta registrada desde Crear cuenta de bodeguero: puede consultar y registrar movimientos, pero no administrar catálogos ni cerrar órdenes.

Los selectores permiten buscar y paginar; pulsa Enter para aplicar su búsqueda. El botón Quitar filtro también permite quitar una selección opcional.

## Roles

| Operación | ADMIN | BODEGUERO |
|---|---|---|
| Consultar todos los módulos | Sí | Sí |
| Crear, editar y eliminar categorías/productos/equipos | Sí | No |
| Abrir y cerrar mantenimientos | Sí | No |
| Registrar entradas y salidas | Sí | Sí |

La API verifica los permisos aunque se intente acceder mediante una URL directa. El token se guarda con `flutter_secure_storage`; ante un 401 se limpia la sesión. En web usa HTTPS al publicar y evita equipos compartidos.

## Estructura y convenciones

```text
lib/
  core/theme/          Tema Material 3 y espaciados
  data/models/         Datos recibidos de la API
  data/repositories/   Contratos, cliente Dio e implementación HTTP
  providers/           Sesión y estado por entidad
  ui/atoms/            Botones, campos y badges
  ui/molecules/        Búsqueda, filtros y mensajes
  ui/organisms/        Tarjetas y estados de lista
  ui/templates/        Navegación adaptable
  ui/pages/            Pantallas y formularios
```

Cada carpeta expone un archivo de exportaciones. Por ejemplo:

```dart
// molecules.dart
export 'app_snack_bar.dart';
export 'filter_chips_row.dart';
export 'search_field.dart';

// En una pantalla
import '../molecules/molecules.dart';
```

Los consumidores importan el archivo de su grupo. Los archivos de una misma carpeta mantienen imports directos entre sí para evitar ciclos. Los paquetes externos conservan sus imports explícitos.

Los providers dependen del contrato `GestionRepository`, no de Dio. Cada entidad tiene su provider; las pantallas reutilizan listas y formularios comunes. Los organismos reciben datos y callbacks. La navegación usa `go_router` con protección de sesión y rol. Los colores y espaciados salen del tema; el perfil permite elegir tema claro, oscuro o del sistema.

## Verificación

```powershell
flutter analyze
flutter test
flutter build web --dart-define=API_URL=http://localhost:3000
```

Las 24 pruebas de Flutter cubren carga, filtros, errores, guardado, respuestas atrasadas, dispose, sesión, validación de login, rutas protegidas y widgets.

Para verificar la integración real, deja la API encendida y ejecuta en su carpeta:

```powershell
npm run test:integration
```

Estas 8 pruebas crean registros identificados para la prueba y los conservan como historial en la base local: permisos, CRUD, validación, consumo de repuestos, salida excesiva, concurrencia y cierre de órdenes. No ejecutes esta suite contra producción.

## Compilación y entrega

```powershell
flutter build web --dart-define=API_URL=https://TU-API
flutter build apk --release --dart-define=API_URL=https://TU-API
```

La salida web está en `build/web`; el APK, en `build/app/outputs/flutter-apk/app-release.apk`. Antes de distribuir el APK debes configurar una firma propia: la plantilla Android todavía usa firma debug para release. No subas claves de firma al repositorio.

## Estado y pendientes

La integración local está implementada y las pruebas descritas pasaron. La compilación web se verificó. La revisión visual en navegador local quedó bloqueada por la disponibilidad de la herramienta; no se ha verificado el APK en un dispositivo.

Se consultaron los dos Figma en modo público y se reutilizó la base del curso. La lectura detallada del diseño mediante la integración sigue pendiente de autenticación; no se afirma una reproducción exacta de todas las pantallas.

No se ha publicado en Render, conectado una cuenta de Supabase ni creado releases o PRs. La base local usa PostgreSQL; para Supabase hay que configurar sus URLs y las políticas de acceso antes de publicar. Tampoco se ha completado toda la rúbrica académica (por ejemplo RLS, colección Bruno y verificación de CI en GitHub). El proyecto integra ambos dominios por decisión del usuario, aunque el enunciado del examen se centra en inventarios.

## Problemas habituales

- **No conecta:** comprueba `/health`, la URL de compilación y que Docker y la API estén encendidos.
- **CORS en web:** añade el origen exacto del navegador a `CORS_ORIGINS`, separado por comas, y reinicia la API.
- **401:** vuelve a iniciar sesión; el token dura 8 horas.
- **409 al eliminar:** el registro tiene relaciones o historial; consérvalo.
- **409 al consumir:** revisa stock y que la orden siga abierta. Si hubo cambios simultáneos, actualiza y reintenta.
- **Lista vacía:** revisa búsqueda y filtros. El historial de un equipo o producto aplica un filtro al módulo correspondiente.


## Referencias visuales recibidas

Se recibieron capturas del Figma de inventarios y los átomos de mantenimiento. El tema claro utiliza colores extraídos de esas imágenes: fondo #F4FBF8, tarjetas #EFF5F2, navegación #E9EFEC y contenedores #9FF2E1. Las pantallas de equipos y órdenes conservan la semilla azul #0B5FA5; inventario usa #00695C. El tema oscuro se selecciona desde el perfil y se deriva de esas semillas con Material 3: no se recibieron capturas de una paleta oscura para certificar sus valores exactos.

Se ajustaron acceso, tarjetas de producto, badges, búsqueda y estilos compartidos. La navegación integrada, detalles, formularios y perfil todavía requieren una comparación completa con las capturas; no se considera terminada la reproducción visual exacta. La contraseña sigue requiriendo 10 caracteres para mantener coherencia con la API, aunque la referencia muestra 8.

## Automatización

El flujo `.github/workflows/ci.yml` ejecuta análisis, pruebas y compilación web en cada push o Pull Request. Está preparado localmente; su ejecución en GitHub se verificará cuando el proyecto se publique en el repositorio propio. La dirección local usada en esa compilación solo sirve para verificar el build, no es una entrega de producción.

## Procedencia

La base inicial procede del [material de clase de Alex García](https://github.com/alegarciaaitec/app-mantenimiento). Este repositorio inicia un historial propio a partir de su importación; se conserva el crédito del material original en [PROCEDENCIA.md](PROCEDENCIA.md).
