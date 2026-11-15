import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_mantenimiento/providers/providers.dart';

void main() {
  test('cambiar apariencia notifica solo cuando cambia la selección', () {
    final provider = ThemeProvider();
    addTearDown(provider.dispose);
    var cambios = 0;
    provider.addListener(() => cambios++);
    expect(provider.mode, ThemeMode.system);
    provider.cambiar(ThemeMode.dark);
    expect(provider.mode, ThemeMode.dark);
    provider.cambiar(ThemeMode.dark);
    expect(cambios, 1);
    provider.cambiar(ThemeMode.light);
    expect(provider.mode, ThemeMode.light);
    expect(cambios, 2);
  });
}
