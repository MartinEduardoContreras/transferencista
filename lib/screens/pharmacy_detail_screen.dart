import 'package:material_ui/material_ui.dart';

import '../data/app_repository.dart';
import '../models/pharmacy.dart';
import '../models/product_record.dart';
import '../services/location_service.dart';
import '../utils/format.dart';
import '../widgets/info_section.dart';
import 'new_pharmacy_screen.dart';
import 'visit_screen.dart';
import '../widgets/brand_app_bar.dart';

/// Ficha de la farmacia y preparación antes de la visita: qué sabe la
/// transferencista del cliente. Permite editar los datos de la farmacia.
class PharmacyDetailScreen extends StatefulWidget {
  const PharmacyDetailScreen({
    super.key,
    required this.repository,
    required this.pharmacy,
    required this.locationService,
    this.showStartVisit = true,
  });

  final AppRepository repository;
  final Pharmacy pharmacy;
  final LocationService locationService;

  /// Muestra el botón "Iniciar visita" si la farmacia aún no se visitó hoy. Se
  /// oculta cuando la farmacia se consulta desde el listado de Farmacias.
  final bool showStartVisit;

  @override
  State<PharmacyDetailScreen> createState() => _PharmacyDetailScreenState();
}

class _PharmacyDetailScreenState extends State<PharmacyDetailScreen> {
  String? _selectedProduct;

  /// Inventario estimado = unidades de la última visita donde se revisó el producto.
  static String _estimatedUnits(ProductHistoryEntry? entry) {
    if (entry == null) return 'Sin datos';
    return '${entry.record.units} unidades (${formatDate(entry.date)})';
  }

  void _startVisit(Pharmacy pharmacy) {
    // Al finalizar, VisitScreen vuelve a Hoy directamente.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VisitScreen(
          repository: widget.repository,
          pharmacy: pharmacy,
          locationService: widget.locationService,
        ),
      ),
    );
  }

  void _editPharmacy(Pharmacy pharmacy) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewPharmacyScreen(
          repository: widget.repository,
          pharmacy: pharmacy,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = widget.repository;
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        // Se toma la farmacia actual del repositorio, por si acaba de editarse.
        final p = repo.pharmacyById(widget.pharmacy.id) ?? widget.pharmacy;
        final lastVisit = repo.lastVisit(p);
        final visitedToday = repo.wasVisitedToday(p);
        final products = repo.catalog;
        // Inventario estimado solo para productos con registros en esta farmacia.
        final withHistory = [
          for (final product in products)
            if (repo.lastProductRecord(p, product) != null) product,
        ];
        final selected = _selectedProduct ?? (products.isEmpty ? null : products.first);
        final history = selected == null ? null : repo.lastProductRecord(p, selected);

        return Scaffold(
          appBar: BrandAppBar(
            title: p.name,
            actions: [
              IconButton(
                tooltip: 'Editar farmacia',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _editPharmacy(p),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              InfoSection(
                title: 'Información del cliente',
                rows: [
                  InfoRow('Cadena', p.chain),
                  InfoRow('Zona', p.zone),
                  InfoRow('Dirección', p.address.isEmpty ? '—' : p.address),
                  InfoRow(
                    'Responsable',
                    p.manager.isEmpty ? 'Sin responsable' : p.manager,
                  ),
                  InfoRow('Prioridad en la ruta', p.routePriority.label),
                  InfoRow('Última compra', p.lastPurchaseLabel),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Productos', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (selected != null)
                        DropdownButtonFormField<String>(
                          initialValue: selected,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Producto',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            for (final product in products)
                              DropdownMenuItem(value: product, child: Text(product)),
                          ],
                          onChanged: (value) => setState(() => _selectedProduct = value),
                        ),
                      const SizedBox(height: 12),
                      _LastProductRecord(history: history),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InfoSection(
                title: 'Inventario estimado',
                rows: [
                  for (final product in withHistory)
                    InfoRow(product, _estimatedUnits(repo.lastProductRecord(p, product))),
                  if (withHistory.isEmpty)
                    const InfoRow('Sin inventario registrado', '—'),
                ],
              ),
              if (lastVisit != null) ...[
                const SizedBox(height: 12),
                InfoSection(
                  title: 'Última visita',
                  rows: [
                    InfoRow('Fecha', formatDate(lastVisit.arrival)),
                    InfoRow('Duración', '${lastVisit.duration.inMinutes} min'),
                    InfoRow('Productos revisados', '${lastVisit.products.length}'),
                  ],
                ),
              ],
              if (widget.showStartVisit) ...[
                const SizedBox(height: 24),
                if (visitedToday)
                  const Center(
                    child: Text('La visita de hoy a esta farmacia ya está registrada.'),
                  )
                else
                  FilledButton.icon(
                    onPressed: () => _startVisit(p),
                    icon: const Icon(Icons.storefront),
                    label: const Text('Iniciar visita'),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Último registro del producto seleccionado en esta farmacia.
class _LastProductRecord extends StatelessWidget {
  const _LastProductRecord({required this.history});

  final ProductHistoryEntry? history;

  static String _yesNo(bool value) => value ? 'Sí' : 'No';

  @override
  Widget build(BuildContext context) {
    final entry = history;
    if (entry == null) {
      return const Text('Sin registros de este producto en esta farmacia.');
    }
    final r = entry.record;
    return Column(
      children: [
        InfoRow('Última revisión', formatDate(entry.date)),
        InfoRow('Exhibido', _yesNo(r.displayed)),
        InfoRow('Precio visible', _yesNo(r.priceVisible)),
        InfoRow('Producto visible', _yesNo(r.productVisible)),
        InfoRow('Inventario', '${r.units} unidades'),
        InfoRow('Hay competencia', _yesNo(r.competitionPresent)),
        InfoRow('Material POP', _yesNo(r.popPresent)),
        InfoRow('Hay agotados', _yesNo(r.outOfStock)),
      ],
    );
  }
}
