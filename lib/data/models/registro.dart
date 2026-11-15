enum Modulo {
  productos('productos', 'Inventario', 'Producto'),
  categorias('categorias', 'Categorías', 'Categoría'),
  equipos('equipos', 'Equipos', 'Equipo'),
  mantenimientos('mantenimientos', 'Mantenimientos', 'Orden'),
  movimientos('movimientos', 'Movimientos', 'Movimiento');

  const Modulo(this.ruta, this.titulo, this.singular);
  final String ruta;
  final String titulo;
  final String singular;
  bool get maestro =>
      this == productos || this == categorias || this == equipos;
}

class Registro {
  Registro(Map<String, dynamic> json) : datos = Map.unmodifiable(json);
  final Map<String, dynamic> datos;
  String texto(String campo) => datos[campo]?.toString() ?? '';
  int entero(String campo) => (datos[campo] as num?)?.toInt() ?? 0;
  String get id => texto('id');
  String get nombre => texto('nombre');
  String get codigo => texto('codigo');
  String relacionado(String campo, String atributo) =>
      (datos[campo] as Map?)?[atributo]?.toString() ?? '';
  int get stock => entero('stock');
  String get estadoStock => stock == 0
      ? 'Agotado'
      : stock < entero('stockMinimo')
      ? 'Stock bajo'
      : 'Disponible';
  bool get enMantenimiento =>
      (datos['mantenimientos'] as List?)?.isNotEmpty ?? false;
}

class Pagina {
  const Pagina(this.registros, this.total, this.paginas);
  factory Pagina.fromJson(Map<String, dynamic> json) => Pagina(
    (json['data'] as List)
        .map((e) => Registro(Map<String, dynamic>.from(e)))
        .toList(),
    (json['meta'] as Map)['total'] as int,
    (json['meta'] as Map)['totalPages'] as int,
  );
  final List<Registro> registros;
  final int total;
  final int paginas;
}

class Usuario {
  const Usuario({required this.nombre, required this.email, required this.rol});
  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    nombre: json['nombre'] as String,
    email: json['email'] as String,
    rol: json['rol'] as String,
  );
  final String nombre;
  final String email;
  final String rol;
  bool get esAdmin => rol == 'ADMIN';
}
