/// Momento de la foto dentro de la visita.
enum VisitPhotoKind {
  before('Antes'),
  after('Después');

  const VisitPhotoKind(this.label);

  final String label;
}

/// Foto tomada durante la visita (exhibición antes y después de la gestión).
class VisitPhoto {
  const VisitPhoto({
    required this.kind,
    required this.path,
    required this.takenAt,
  });

  final VisitPhotoKind kind;

  /// Ruta local del archivo de la foto.
  final String path;
  final DateTime takenAt;
}
