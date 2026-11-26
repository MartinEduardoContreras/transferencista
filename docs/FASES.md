# Transferencista — Fases de desarrollo

Aplicación Flutter (Android e iOS) para que la transferencista farmacéutica planee su ruta,
prepare cada visita, registre la gestión en el punto de venta y mida sus resultados.
Base funcional: documento *Transferencista en Colombia* (proceso de 8 etapas).

## Mapa de fases

| Fase | Objetivo | Estado |
|------|----------|--------|
| 0 | Fundamentos: proyecto Flutter, arquitectura, tema, pruebas base | Hecho |
| 1 | MVP local: ruta del día, preparación de visita, registro de visita | Hecho (datos de ejemplo) |
| 2 | Evidencia en campo: GPS check-in/out y fotos antes/después (hecho); registro de trayecto transparente (hecho); firma del responsable de la droguería (hecho) | Hecho |
| 3 | Pedido y seguimiento: pedido sugerido, seguimiento a la semana, recompra | Pendiente |
| 4 | Backend: base de datos, sincronización offline, login y roles | Pendiente |
| 5 | Indicadores y piloto: dashboard KPIs, pruebas con usuarios, despliegue | Pendiente |

---

## Fase 0 — Fundamentos (hecho)

- Proyecto `transferencista` creado con `flutter create` solo para `android` e `ios`.
- Estructura por capas:
  - `lib/models/` — entidades del dominio (`Pharmacy`, `Visit`, `PointOfSaleCheck`).
  - `lib/data/` — repositorio y datos de ejemplo (se reemplazará en fase 4).
  - `lib/screens/` — pantallas.
  - `lib/widgets/` — componentes reutilizables.
  - `lib/utils/` — formatos (pesos COP, hora).
- Tema Material 3 con color de marca provisional.
- Pruebas unitarias del repositorio y formato, y una prueba de widget de arranque.

## Fase 1 — MVP local (hecho)

Cubre los pasos 2, 3, 4 y 7 del proceso:

1. **Ruta del día** (`HomeScreen`): farmacias ordenadas por prioridad y cobertura de la jornada
   (meta 95%).
2. **Preparación de la visita** (`PharmacyDetailScreen`): cliente, última compra, producto estrella,
   producto nuevo, productos no comprados, inventario estimado, última visita.
3. **Registro de la visita** (`VisitScreen`):
   - Checklist del punto: exhibido, precio visible, visible, inventario, competencia, material POP,
     agotados.
   - Inventario por producto del portafolio.
   - Competencia y observaciones.
   - Hora de llegada y salida.

Limitaciones actuales: los datos viven en memoria (se pierden al cerrar la app) y las farmacias son ficticias.

## Fase 2 — Evidencia en campo (pendiente)

- Check-in y check-out con GPS (paso 7: hora de llegada/salida y GPS).
- Fotos antes y después de la gestión (paso 6).
- Registro de material POP instalado y capacitación realizada.
- Firma digital del responsable de la farmacia.
- Permisos de ubicación y cámara en Android e iOS (`Info.plist` y `AndroidManifest.xml`).

## Fase 3 — Pedido y seguimiento (pendiente)

- Pedido sugerido según inventario y rotación (paso 7: pedido sugerido/realizado).
- Promociones, bonificaciones y obsequios aplicados en la visita (paso 5).
- Seguimiento a una semana: ¿vendió?, ¿rotó?, ¿hay agotado?, ¿hay devolución? (paso 8).
- Planeación semanal y priorización por volumen, potencial, días sin compra, inventario y crecimiento (paso 1).

## Fase 4 — Backend y offline (pendiente)

- Base de datos local (SQLite/Drift o Isar) para trabajar sin señal y sincronizar después.
- API y base de datos central, con cola de sincronización y resolución de conflictos.
- Autenticación y roles: transferencista, supervisor, administrador.
- Carga de catálogo de productos y clientes desde el laboratorio.

## Fase 5 — Indicadores y piloto (pendiente)

- Dashboard en tiempo real con los KPIs del documento: cobertura, cumplimiento de visitas,
  activación de productos nuevos, rotación antes/después, participación vs competencia,
  días de inventario, cumplimiento de planograma, material POP, auxiliares entrenados,
  conversión y recompra.
- Piloto con 2–3 transferencistas en una zona (Zona Norte Bogotá como referencia).
- Despliegue: Google Play (pruebas internas/cerradas) y TestFlight para iPhone.
- Ajustes según retroalimentación del piloto.

---

## Cómo ejecutar

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Para Android se necesita un emulador o dispositivo con depuración USB; para iPhone, un Mac con Xcode
(compilar para iOS no es posible desde Windows). Ver `flutter doctor` para el estado del entorno.

## Decisiones abiertas para el equipo

1. Nombre comercial y color de marca (hoy es un color provisional).
2. Laboratorio y portafolio real de productos (hoy: Sertralina, K-Llosil, Melatonina, Omega 3, Vitaminas — ejemplo).
3. Backend preferido: Firebase, Supabase u otro proveedor propio.
4. Si el checklist y los KPIs deben ser parametrizables por el laboratorio o fijos.
5. Cuenta de Apple Developer y de Google Play para publicar.
