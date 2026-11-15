# Estado de revisión de la entrega

Se mantienen Inventarios y Mantenimiento al mismo nivel por decisión del proyecto. Esto difiere del enunciado de Inventarios y debe explicarse al docente.

## Comprobado localmente

- Flutter: análisis sin avisos y 24 pruebas aprobadas.
- API: lint sin errores, 12 pruebas unitarias y ocho pruebas e2e aprobadas.
- Suite HTTP adicional de ocho escenarios implementada, incluyendo stock insuficiente y concurrencia; ejecutada durante la integración inicial.
- Providers por entidad y sesión, registrados en la raíz; contratos de repositorio.
- Tema claro, oscuro y sistema seleccionables desde perfil.
- Errores Dio traducidos a ApiException en los repositorios.
- Confirmación de guardado y registro de movimientos.
- Flujos de CI aprobados en ambos repositorios. Los cambios posteriores vuelven a ejecutar las verificaciones.

## Pendientes que no deben presentarse como terminados

- Comparación visual completa con ambos Figma; la paleta oscura no tiene captura de referencia.
- Formularios y detalles todavía usan estado local para algunos datos cargados.
- Confirmación al descartar cambios del formulario.
- RLS, revisión completa de seguridad y colección Bruno.
- APK release con firma propia, icono propio y prueba de instalación.
- API pública en Render y URL real documentada.
- Capturas de la app ejecutándose, distintas de las referencias Figma.
- Repositorios propios, historial real de tareas y PRs, Release de GitHub.

No se reconstruirá un historial ficticio de tareas ni se declararán aprobadas verificaciones que no se han ejecutado.
