import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Guarda la firma (PNG) en la carpeta de documentos de la app, para que no se
/// borre con la caché del sistema. Devuelve la ruta guardada.
Future<String> saveSignaturePng(Uint8List bytes) async {
  final docs = await getApplicationDocumentsDirectory();
  final folder = Directory(p.join(docs.path, 'firmas'));
  await folder.create(recursive: true);
  final savedPath = p.join(
    folder.path,
    '${DateTime.now().microsecondsSinceEpoch}_firma.png',
  );
  await File(savedPath).writeAsBytes(bytes);
  return savedPath;
}
