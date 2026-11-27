import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// Pantalla de inicio: logo Medical Farma y el texto "Transferencista & Impulsor"
/// que crece desde pequeño hasta llenar el ancho de la pantalla. Al terminar llama
/// a [onFinished].
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onFinished,
    this.duration = const Duration(milliseconds: 2600),
  });

  final VoidCallback onFinished;
  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _growMs = 1800;
  static const _maxFontSize = 80.0;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, () {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo_medical_farma.png', width: 240),
                const SizedBox(height: 28),
                // El tamaño crece de 16 a 80. Como el texto es más ancho que la
                // pantalla, FittedBox lo reduce para que quepa: el crecimiento se
                // detiene justo cuando llena el ancho disponible.
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 16, end: _maxFontSize),
                  duration: const Duration(milliseconds: _growMs),
                  curve: Curves.easeOutCubic,
                  builder: (context, fontSize, _) => FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Transferencista & Impulsor',
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
