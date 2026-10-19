import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../domain/models/orden.dart';

/// Panel de métricas del Dashboard con diseño SaaS profesional (KPI cards independientes)
class MetricasPanel extends StatelessWidget {
  const MetricasPanel({super.key, required this.metricas});

  final MetricasOrdenes metricas;

  @override
  Widget build(BuildContext context) {
    final minutos = (metricas.segPromedioEntrega / 60).toStringAsFixed(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final esPantallaAncha = constraints.maxWidth > 650;

        final cards = [
          _KpiCard(
            titulo: 'Órdenes Cerradas',
            valor: '${metricas.ordenesCerradas}',
            subtitulo: 'Entregadas con éxito',
            icono: Icons.verified_outlined,
            colorIcono: Colors.green,
            colorFondo: const Color(0xFFF0FDF4),
          ),
          _KpiCard(
            titulo: 'Imágenes Procesadas',
            valor: '${metricas.imagenesProcesadas}',
            subtitulo: 'Sin fondo con rembg',
            icono: Icons.auto_awesome,
            colorIcono: AppColors.primary,
            colorFondo: const Color(0xFFEFF6FF),
          ),
          _KpiCard(
            titulo: 'Tiempo Promedio',
            valor: '$minutos m',
            subtitulo: 'Ciclo completo E2E',
            icono: Icons.timer_outlined,
            colorIcono: const Color(0xFF8B5CF6),
            colorFondo: const Color(0xFFF5F3FF),
          ),
        ];

        if (esPantallaAncha) {
          return Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
              const SizedBox(width: 16),
              Expanded(child: cards[2]),
            ],
          );
        }

        return Column(
          children: [
            cards[0],
            const SizedBox(height: 12),
            cards[1],
            const SizedBox(height: 12),
            cards[2],
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.titulo,
    required this.valor,
    required this.subtitulo,
    required this.icono,
    required this.colorIcono,
    required this.colorFondo,
  });

  final String titulo;
  final String valor;
  final String subtitulo;
  final IconData icono;
  final Color colorIcono;
  final Color colorFondo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorFondo,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: colorIcono, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
