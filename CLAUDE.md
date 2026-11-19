# Transferencista — contexto para Claude Code

## Qué es

Aplicación Flutter (Android e iOS) para que la transferencista farmacéutica en Colombia
planee su ruta semanal, prepare cada visita, registre la gestión en el punto de venta y mida
resultados. Está basada en el documento *Transferencia Comercial en Colombia* (proceso de 8
etapas: planeación, preparación, visita, activación, material POP, registro en app,
seguimiento y recompra). El detalle está en `docs/FASES.md`.

Idioma de la app, comentarios y documentación: **español**.

## Fases

| Fase | Alcance | Estado |
|------|---------|--------|
| 0 | Fundamentos: proyecto Flutter, arquitectura, tema, pruebas base | Hecho |
| 1 | MVP local: ruta del día, preparación de visita, registro de visita (datos de ejemplo en memoria) | Hecho |
| 2 | GPS check-in/out, fotos antes/después, firma, permisos de ubicación y cámara | Pendiente |
| 3 | Pedido sugerido, promociones, seguimiento a una semana, planeación semanal | Pendiente |
| 4 | Base de datos local offline, backend, sincronización, login y roles | Pendiente |
| 5 | Dashboard de KPIs, piloto, despliegue en Google Play e iOS (TestFlight) | Pendiente |

Trabaja en la fase pendiente más baja salvo que se indique otra cosa. No adelantes funciones de
fases posteriores sin pedirlo.

## Comandos

```bash
flutter pub get      # instalar dependencias
flutter analyze      # análisis estático; debe quedar en "No issues found!"
flutter test         # pruebas unitarias y de widgets
flutter run          # ejecutar en el dispositivo o emulador seleccionado
flutter run -d chrome  # vista previa en navegador
```

Antes de dar por terminado un cambio, ejecuta `flutter analyze` y `flutter test`.

## Requisitos del entorno

- Flutter 3.50.0 o superior (Dart 3.14 o superior). El `pubspec.yaml` exige `sdk: ^3.14.0`.
- La UI usa el paquete `material_ui` en lugar de `package:flutter/material.dart`. Usa siempre
  `import 'package:material_ui/material_ui.dart';` en código nuevo.
- En Windows sin emulador acelerado, prueba con `flutter run -d chrome` o con un teléfono físico.

## Estructura del proyecto

```
lib/
  main.dart                    arranque de la app
  app.dart                     MaterialApp y tema
  models/
    pharmacy.dart              Pharmacy: farmacia o punto de venta
    visit.dart                 Visit y enum PointOfSaleCheck (checklist del punto)
  data/
    app_repository.dart        AppRepository: ruta, visitas (en memoria)
    seed_data.dart             datos de ejemplo (farmacias y portafolio ficticios)
  screens/
    home_screen.dart           ruta del día y cobertura
    pharmacy_detail_screen.dart  preparación de la visita
    visit_screen.dart          registro de la visita
  widgets/
    info_section.dart          InfoSection e InfoRow (tarjetas clave/valor)
  utils/
    format.dart                formatCop (pesos COP) y formatTime (HH:mm)
test/
  widget_test.dart             pruebas del repositorio, formato y arranque de la app
docs/
  FASES.md                     plan de fases y decisiones abiertas
```

## Convenciones

- Entidades de dominio en `lib/models/`; no mezclar lógica de UI con modelos.
- Los datos pasan por `AppRepository`. Las pantallas no deben tener datos de ejemplo embebidos.
  Cuando llegue la fase 4, reemplaza la implementación del repositorio sin cambiar sus métodos
  públicos cuando sea posible.
- Los datos de `seed_data.dart` son ficticios. No introducir datos reales de farmacias ni de
  clientes en el repositorio.
- Nombres de clases en inglés con términos del dominio en español cuando ya existen en el
  documento (`Pharmacy`, `Visit`; usa "farmacia" en textos visibles).
- Pesos colombianos con `formatCop`; horas con `formatTime`. No añadir `intl` sin pedirlo.
- No añadir paquetes nuevos sin consultarlo; cada dependencia nueva afecta a Android e iOS.

## Git

- Rama principal: `master`. Remoto: `origin` (repositorio privado en GitHub).
- Mensajes de commit en español, en imperativo y cortos.
- No subas archivos generados (`build/`, `.dart_tool/`, `android/local.properties`).
- `.metadata` lo modifica Flutter solo; no lo incluyas en commits de funcionalidad.
