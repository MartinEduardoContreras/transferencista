import 'package:material_ui/material_ui.dart';

import '../data/app_repository.dart';
import '../models/pharmacy.dart';
import '../utils/format.dart';

/// Plan de visitas: elige una fecha y ordena las farmacias en el orden de visita.
/// Los cambios se guardan al momento.
class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key, required this.repository});

  final AppRepository repository;

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  late DateTime _day = startOfDay(DateTime.now());

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _day = startOfDay(picked));
  }

  Future<void> _addPharmacy(List<String> currentIds) async {
    final available = widget.repository.pharmacies
        .where((p) => !currentIds.contains(p.id))
        .toList();
    final picked = await showModalBottomSheet<Pharmacy>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final pharmacy in available)
              ListTile(
                title: Text(pharmacy.name),
                subtitle: Text(pharmacy.zone),
                onTap: () => Navigator.of(sheetContext).pop(pharmacy),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      widget.repository.setPlan(_day, [...currentIds, picked.id]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = widget.repository;
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final ids = repo.planIds(_day);
        final planned = repo.planFor(_day);
        final hasAvailable = repo.pharmacies.any((p) => !ids.contains(p.id));

        return Scaffold(
          appBar: AppBar(title: const Text('Plan de visitas')),
          body: Column(
            children: [
              Card(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          formatDate(_day),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.edit_calendar),
                        label: const Text('Cambiar fecha'),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Orden de visita · arrastra para cambiarlo',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              Expanded(
                child: planned.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No hay farmacias planeadas para este día. '
                            'Agrega una con el botón de abajo.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ReorderableListView(
                        onReorderItem: (oldIndex, newIndex) {
                          final updated = [...ids];
                          final moved = updated.removeAt(oldIndex);
                          updated.insert(newIndex, moved);
                          repo.setPlan(_day, updated);
                        },
                        children: [
                          for (var i = 0; i < planned.length; i++)
                            ListTile(
                              key: ValueKey(planned[i].id),
                              leading: CircleAvatar(child: Text('${i + 1}')),
                              title: Text(planned[i].name),
                              subtitle: Text(planned[i].zone),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Quitar del plan',
                                    icon: const Icon(Icons.close),
                                    onPressed: () => repo.setPlan(
                                      _day,
                                      [...ids]..remove(planned[i].id),
                                    ),
                                  ),
                                  const Icon(Icons.drag_handle),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: hasAvailable ? () => _addPharmacy(ids) : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar farmacia'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
