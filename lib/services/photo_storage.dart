import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Toma una foto con la cámara y la copia a la carpeta de documentos de la app,
/// para que no se borre con la caché del sistema. [tag] va en el nombre del archivo.
/// Devuelve la ruta guardada, o null si la persona cancela.
Future<String?> takeVisitPhoto(String tag) async {
  final shot = await ImagePicker().pickImage(
    source: ImageSource.camera,
    maxWidth: 1280,
    imageQuality: 70,
  );
  if (shot == null) return null;

  final docs = await getApplicationDocumentsDirectory();
  final folder = Directory(p.join(docs.path, 'fotos_visitas'));
  await folder.create(recursive: true);
  final savedPath = p.join(
    folder.path,
    '${DateTime.now().microsecondsSinceEpoch}_$tag.jpg',
  );
  await File(shot.path).copy(savedPath);
  return savedPath;
}
