import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import 'upload_card.dart';

/// Sección hero de la página inicial.
/// Muestra el headline a la izquierda y [UploadCard] a la derecha.
class HeroSection extends StatelessWidget {
  const HeroSection({
    super.key,
    required this.onCargar,
    this.procesando = false,
  });

  final VoidCallback? onCargar;
  final bool procesando;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _buildHeadline()),
        const SizedBox(width: 40),
        Expanded(
          child: UploadCard(onCargar: onCargar, procesando: procesando),
        ),
      ],
    );
  }

  Widget _buildHeadline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quita el fondo.\nQuédate con lo esencial.',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            height: 1.1,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            const Text(
              'Automático, rápido y ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryAccent],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'gratis',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
