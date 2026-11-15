import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../providers/providers.dart';
import '../atoms/atoms.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.registro = false});
  final bool registro;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscure = true;
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _nombre = TextEditingController();
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _nombre.dispose();
    super.dispose();
  }

  void _submit() {
    if (_form.currentState!.validate()) {
      context.read<SessionProvider>().ingresar(
        _email.text,
        _password.text,
        nombre: widget.registro ? _nombre.text : null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          Icons.inventory_2,
                          size: Spacing.xxl,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.xl),
                    Text(
                      widget.registro ? 'Crear cuenta' : 'Inventarios',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      widget.registro
                          ? 'Tu rol será BODEGUERO.'
                          : 'Inicia sesión para continuar',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: Spacing.xxl),
                    if (widget.registro) ...[
                      AppTextField(
                        label: 'Nombre',
                        controller: _nombre,
                        validator: (v) => (v?.trim().length ?? 0) < 2
                            ? 'Escribe tu nombre.'
                            : null,
                      ),
                      const SizedBox(height: Spacing.lg),
                    ],
                    AppTextField(
                      label: 'Correo',
                      suffixIcon: const Icon(Icons.email),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          !RegExp(
                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                          ).hasMatch(v?.trim() ?? '')
                          ? 'Escribe un correo válido.'
                          : null,
                    ),
                    const SizedBox(height: Spacing.lg),
                    AppTextField(
                      label: 'Contraseña',
                      controller: _password,
                      obscure: _obscure,
                      suffixIcon: IconButton(
                        tooltip: _obscure
                            ? 'Mostrar contraseña'
                            : 'Ocultar contraseña',
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                      helper: widget.registro ? 'Mínimo 10 caracteres' : null,
                      validator: (v) => (v?.length ?? 0) < 10
                          ? 'Usa al menos 10 caracteres.'
                          : null,
                    ),
                    if (session.error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: Spacing.lg,
                        ),
                        child: Text(
                          session.error!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    const SizedBox(height: Spacing.xl),
                    FilledButton(
                      onPressed: session.ocupado ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.md),
                        child: Text(
                          session.ocupado
                              ? 'Conectando…'
                              : widget.registro
                              ? 'Crear cuenta'
                              : 'Iniciar sesión',
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    TextButton(
                      onPressed: session.ocupado
                          ? null
                          : () => context.go(
                              widget.registro ? '/login' : '/registro',
                            ),
                      child: Text(
                        widget.registro ? 'Ya tengo cuenta' : 'Crear cuenta',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
