# Convenciones

- Mantener un archivo de exportación por carpeta: atoms.dart, molecules.dart, organisms.dart, pages.dart, models.dart, repositories.dart y providers.dart.
- Desde otra carpeta, importar ese archivo en lugar de enumerar componentes. Dentro de la misma carpeta usar imports directos para evitar ciclos.
- No agrupar paquetes externos en un archivo global.
- Comentarios breves solo para decisiones que el código no explique.
- Actualizar el README cuando cambien configuración, comandos o flujos de uso.
- Las pantallas no acceden a Dio: usan providers y contratos de repositorios.
- Ejecutar flutter analyze y flutter test después de cambios funcionales.
- Usar Conventional Commits: feat:, fix:, test:, docs: y chore:, con descripción concreta en español.
