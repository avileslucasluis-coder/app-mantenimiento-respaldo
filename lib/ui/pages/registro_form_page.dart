import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../providers/providers.dart';
import '../atoms/atoms.dart';
import '../organisms/organisms.dart';
import 'coleccion_page.dart';

class RegistroFormPage extends StatefulWidget {
  const RegistroFormPage({
    super.key,
    required this.modulo,
    this.id,
    this.ordenId,
  });
  final Modulo modulo;
  final String? id;
  final String? ordenId;
  @override
  State<RegistroFormPage> createState() => _RegistroFormPageState();
}

class _RegistroFormPageState extends State<RegistroFormPage> {
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  final _references = <String, String>{};
  final _labels = <String, String>{};
  late CollectionProvider _provider;
  bool _loading = false;
  String? _error;
  String _tipo = '';
  bool _confirmando = false;
  TextEditingController _field(String key, [String value = '']) =>
      _fields.putIfAbsent(key, () => TextEditingController(text: value));
  @override
  void initState() {
    super.initState();
    _provider = context.read<GestionScope>().of(widget.modulo);
    _tipo = widget.modulo == Modulo.mantenimientos
        ? 'PREVENTIVO'
        : widget.ordenId == null
        ? 'ENTRADA'
        : 'SALIDA';
    if (widget.ordenId != null) {
      _references['mantenimientoId'] = widget.ordenId!;
      _labels['mantenimientoId'] = 'Orden seleccionada';
    }
    if (widget.id != null) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final item = await _provider.repository.obtener(widget.id!);
      if (!mounted) return;
      final keys = [
        'nombre',
        'descripcion',
        if (widget.modulo != Modulo.categorias) 'codigo',
        if (widget.modulo == Modulo.productos) ...[
          'precio',
          'stockMinimo',
          'unidad',
        ],
        if (widget.modulo == Modulo.equipos) 'ubicacion',
      ];
      for (final key in keys) {
        _field(key).text = item.texto(key);
      }
      if (item.texto('categoriaId').isNotEmpty) {
        _references['categoriaId'] = item.texto('categoriaId');
        _labels['categoriaId'] = item.relacionado('categoria', 'nombre');
      }
    } catch (e) {
      _error = mensajeError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _input(
    String key,
    String label, {
    bool required = true,
    bool number = false,
    String initial = '',
    int max = 100,
    int min = 2,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: Spacing.lg),
    child: AppTextField(
      label: label,
      controller: _field(key, initial),
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      validator: (value) {
        final text = value?.trim() ?? '';
        if (required && text.length < min && !number) {
          return 'Escribe al menos $min caracteres.';
        }
        if (text.length > max) return 'Máximo $max caracteres.';
        if (number) {
          final n = num.tryParse(text.replaceAll(',', '.'));
          if (n == null || n < (key == 'cantidad' ? 1 : 0) || !n.isFinite) {
            return 'Ingresa un número válido.';
          }
          if (key != 'precio' && (n != n.roundToDouble() || n > 1000000)) {
            return 'Usa un entero de hasta 1 000 000.';
          }
          if (key == 'precio' &&
              (n > 9999999999 ||
                  (n * 100 - (n * 100).round()).abs() > 0.00001)) {
            return 'Usa hasta 2 decimales y un precio válido.';
          }
        }
        return null;
      },
    ),
  );
  Widget _reference(
    String key,
    String label,
    Modulo modulo, {
    bool optional = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: Spacing.lg),
    child: FormField<String>(
      validator: (_) => !optional && !_references.containsKey(key)
          ? 'Selecciona $label.'
          : null,
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.search),
            label: Text(
              '$label: ${_labels[key] ?? (optional ? 'opcional' : 'seleccionar')}',
            ),
            onPressed: () async {
              final scope = context.read<GestionScope>();
              final id = await showDialog<String>(
                context: context,
                builder: (_) => SelectorRegistros(modulo: modulo),
              );
              if (id == null || !mounted) return;
              if (id.isEmpty) {
                setState(() {
                  _references.remove(key);
                  _labels.remove(key);
                });
                state.didChange(null);
                return;
              }
              try {
                final item = await scope.of(modulo).repository.obtener(id);
                if (!mounted) return;
                if (modulo == Modulo.mantenimientos &&
                    item.texto('estado') != 'ABIERTO') {
                  setState(() => _error = 'Selecciona una orden abierta.');
                  return;
                }
                setState(() {
                  _references[key] = id;
                  _labels[key] = item.nombre.isNotEmpty
                      ? item.nombre
                      : item.relacionado('equipo', 'nombre');
                  _error = null;
                });
                state.didChange(id);
              } catch (e) {
                if (mounted) setState(() => _error = mensajeError(e));
              }
            },
          ),
          if (state.hasError)
            Text(
              state.errorText!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
  );
  Future<void> _save() async {
    if (_confirmando || _provider.guardando) return;
    if (!_form.currentState!.validate()) return;
    final data = <String, dynamic>{};
    for (final entry in _fields.entries) {
      data[entry.key] = entry.value.text.trim();
    }
    for (final key in ['precio', 'stockMinimo', 'cantidad']) {
      if (data.containsKey(key)) {
        data[key] = num.parse((data[key] as String).replaceAll(',', '.'));
      }
    }
    data.addAll(_references);
    if (!widget.modulo.maestro) data['tipo'] = _tipo;
    _confirmando = true;
    final movimiento = widget.modulo == Modulo.movimientos;
    final aceptado = await confirmar(
      context,
      movimiento
          ? '¿Registrar la ${_tipo == 'ENTRADA' ? 'entrada' : 'salida'}?'
          : '¿Guardar ${widget.modulo.singular.toLowerCase()}?',
      movimiento
          ? '${_tipo == 'ENTRADA' ? 'Se sumarán' : 'Se descontarán'} ${data['cantidad']} unidades de «${_labels['productoId']}». Los movimientos no se pueden editar ni eliminar.'
          : 'Se guardarán los datos de «${data['nombre'] ?? data['descripcion']}».',
    );
    _confirmando = false;
    if (!aceptado || !mounted) return;
    final scope = context.read<GestionScope>();
    final ok = await _provider.guardar(data, id: widget.id);
    if (!mounted) return;
    if (!ok) {
      setState(() => _error = _provider.error);
      return;
    }
    await scope.actualizarRelacionados(widget.modulo);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registro guardado correctamente.')),
    );
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go('/${widget.modulo.ruta}');
    }
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: _provider,
    child: Consumer<CollectionProvider>(
      builder: (context, provider, _) {
        final modulo = widget.modulo;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              '${widget.id == null ? 'Crear' : 'Editar'} ${modulo.singular.toLowerCase()}',
            ),
          ),
          body: _loading
              ? const SkeletonCard()
              : widget.id != null && _fields.isEmpty && _error != null
              ? EstadoView(
                  titulo: 'No se pudo cargar',
                  mensaje: _error!,
                  onRetry: _load,
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 650),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(Spacing.xl),
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (modulo.maestro) ...[
                              if (modulo != Modulo.categorias)
                                _input('codigo', 'Código', max: 50),
                              _input('nombre', 'Nombre'),
                              if (modulo == Modulo.equipos)
                                _input('ubicacion', 'Ubicación', max: 150),
                              _input(
                                'descripcion',
                                'Descripción',
                                required: false,
                                max: 1000,
                              ),
                            ],
                            if (modulo == Modulo.productos) ...[
                              _reference(
                                'categoriaId',
                                'Categoría',
                                Modulo.categorias,
                              ),
                              _input(
                                'precio',
                                'Precio unitario',
                                number: true,
                                initial: '0',
                              ),
                              _input(
                                'stockMinimo',
                                'Stock mínimo',
                                number: true,
                                initial: '5',
                              ),
                              _input(
                                'unidad',
                                'Unidad de medida',
                                initial: 'unidad',
                                max: 30,
                                min: 1,
                              ),
                              const Text(
                                'El stock cambia únicamente al registrar entradas y salidas.',
                              ),
                            ],
                            if (modulo == Modulo.mantenimientos)
                              _reference('equipoId', 'Equipo', Modulo.equipos),
                            if (modulo == Modulo.movimientos)
                              _reference(
                                'productoId',
                                'Producto',
                                Modulo.productos,
                              ),
                            if (!modulo.maestro) ...[
                              DropdownButtonFormField<String>(
                                initialValue: _tipo,
                                decoration: const InputDecoration(
                                  labelText: 'Tipo',
                                ),
                                items: [
                                  for (final tipo
                                      in modulo == Modulo.mantenimientos
                                          ? ['PREVENTIVO', 'CORRECTIVO']
                                          : ['ENTRADA', 'SALIDA'])
                                    DropdownMenuItem(
                                      value: tipo,
                                      child: Text(
                                        tipo == 'PREVENTIVO'
                                            ? 'Preventivo'
                                            : tipo == 'CORRECTIVO'
                                            ? 'Correctivo'
                                            : tipo == 'ENTRADA'
                                            ? 'Entrada'
                                            : 'Salida',
                                      ),
                                    ),
                                ],
                                onChanged: (value) => setState(() {
                                  _tipo = value!;
                                  if (_tipo == 'ENTRADA') {
                                    _references.remove('mantenimientoId');
                                    _labels.remove('mantenimientoId');
                                  }
                                }),
                              ),
                              const SizedBox(height: Spacing.lg),
                            ],
                            if (modulo == Modulo.mantenimientos)
                              _input(
                                'descripcion',
                                'Trabajo a realizar',
                                min: 3,
                                max: 1000,
                              ),
                            if (modulo == Modulo.movimientos) ...[
                              _input(
                                'cantidad',
                                'Cantidad',
                                number: true,
                                initial: '1',
                              ),
                              _input(
                                'motivo',
                                'Motivo',
                                required: false,
                                max: 1000,
                              ),
                              if (_tipo == 'SALIDA')
                                _reference(
                                  'mantenimientoId',
                                  'Orden de mantenimiento',
                                  Modulo.mantenimientos,
                                  optional: true,
                                ),
                              const Text(
                                'Los movimientos quedan en el historial y no se pueden editar ni eliminar.',
                              ),
                            ],
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: Spacing.lg,
                                ),
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            const SizedBox(height: Spacing.xl),
                            FilledButton.icon(
                              onPressed: provider.guardando ? null : _save,
                              icon: const Icon(Icons.check),
                              label: Padding(
                                padding: const EdgeInsets.all(Spacing.md),
                                child: Text(
                                  provider.guardando ? 'Guardando…' : 'Guardar',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    ),
  );
}
