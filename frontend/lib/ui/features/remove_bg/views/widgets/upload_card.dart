import 'package:flutter/material.dart';

import 'gradient_button.dart';

/// Tarjeta de carga de imagen con botón principal y texto de ayuda.
class UploadCard extends StatelessWidget {
  const UploadCard({
    super.key,
    required this.onCargar,
    this.procesando = false,
  });

  final VoidCallback? onCargar;
  final bool procesando;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 60,
            offset: const Offset(0, 25),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          GradientButton(
            label: 'Cargar imagen',
            onPressed: procesando ? null : onCargar,
          ),
          const SizedBox(height: 24),
          const Text(
            'o arrastra un archivo,',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'pega la imagen o ',
                style: TextStyle(color: Colors.black54),
              ),
              InkWell(
                onTap: () {},
                child: const Text(
                  'URL',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Formatos: JPEG, PNG, WEBP',
            style: TextStyle(fontSize: 11, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
