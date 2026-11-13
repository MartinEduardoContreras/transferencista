import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'data/app_repository.dart';

void main() {
  runApp(TransferencistaApp(repository: AppRepository.seeded()));
}
