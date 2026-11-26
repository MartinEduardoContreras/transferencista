import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

/// Trazos de una firma. Las coordenadas se guardan entre 0 y 1 (relativas al
/// recuadro), así el PNG sale igual sin importar el tamaño de la pantalla.
class SignatureController extends ChangeNotifier {
  final List<List<ui.Offset>> _strokes = [];
  double _aspect = 0.4; // alto / ancho del recuadro

  List<List<ui.Offset>> get strokes => _strokes;

  bool get isEmpty => _strokes.isEmpty;

  void setAspect(double aspect) => _aspect = aspect;

  void startStroke(ui.Offset point) {
    _strokes.add([point]);
    notifyListeners();
  }

  void addPoint(ui.Offset point) {
    if (_strokes.isEmpty) return;
    _strokes.last.add(point);
    notifyListeners();
  }

  void clear() {
    _strokes.clear();
    notifyListeners();
  }

  /// Exporta la firma como PNG sobre fondo blanco, con 900 px de ancho.
  Future<Uint8List?> toPng() async {
    if (isEmpty) return null;
    const width = 900.0;
    final size = ui.Size(width, width * _aspect);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Offset.zero & size);
    canvas.drawRect(ui.Offset.zero & size, ui.Paint()..color = const ui.Color(0xFFFFFFFF));
    paintSignature(canvas, size, _strokes, const ui.Color(0xFF1B2A41));
    final image = await recorder.endRecording().toImage(
          size.width.round(),
          size.height.round(),
        );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }
}

/// Dibuja los trazos normalizados dentro de [size].
void paintSignature(
  ui.Canvas canvas,
  ui.Size size,
  List<List<ui.Offset>> strokes,
  ui.Color color,
) {
  final paint = ui.Paint()
    ..color = color
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = size.width * 0.009
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round;
  for (final stroke in strokes) {
    final points = [
      for (final p in stroke) ui.Offset(p.dx * size.width, p.dy * size.height),
    ];
    final path = ui.Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    if (points.length == 1) path.lineTo(points.first.dx + 0.1, points.first.dy);
    canvas.drawPath(path, paint);
  }
}

/// Recuadro para firmar con el dedo o un lápiz óptico.
class SignaturePad extends StatelessWidget {
  const SignaturePad({super.key, required this.controller, this.height = 200});

  final SignatureController controller;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        controller.setAspect(height / width);
        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) => Container(
            height: height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) => controller.startStroke(
                    _normalize(context, details.localPosition),
                  ),
                  onPanUpdate: (details) => controller.addPoint(
                    _normalize(context, details.localPosition),
                  ),
                  child: CustomPaint(
                    size: Size(width, height),
                    painter: _SignaturePainter(controller, const Color(0xFF1B2A41)),
                  ),
                ),
                if (controller.isEmpty)
                  IgnorePointer(
                    child: Center(
                      child: Text(
                        'Firme aquí con el dedo o el lápiz',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static ui.Offset _normalize(BuildContext context, ui.Offset local) {
    final box = context.findRenderObject()! as RenderBox;
    return ui.Offset(local.dx / box.size.width, local.dy / box.size.height);
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.controller, this.color) : super(repaint: controller);

  final SignatureController controller;
  final ui.Color color;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    paintSignature(canvas, size, controller.strokes, color);
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
