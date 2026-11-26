import 'package:material_ui/material_ui.dart';

/// Barra superior de la app: logo de Medical Farma seguido del título de la pantalla.
class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandAppBar({super.key, required this.title, this.subtitle});

  static const double _toolbarHeight = 72;
  static const double _logoHeight = 56;

  final String title;
  final String? subtitle;

  @override
  Size get preferredSize => const Size.fromHeight(_toolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: _toolbarHeight,
      title: Row(
        children: [
          Image.asset('assets/images/logo_medical_farma.png', height: _logoHeight),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, overflow: TextOverflow.ellipsis),
                if (subtitle != null)
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
