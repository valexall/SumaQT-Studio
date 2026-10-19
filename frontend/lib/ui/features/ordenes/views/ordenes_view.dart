import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/orden.dart';
import '../view_models/ordenes_view_model.dart';
import 'widgets/archivo_item.dart';
import 'widgets/cola_control_bar.dart';
import 'widgets/dialog_comparar_lote.dart';
import 'widgets/dialog_editar_orden.dart';
import 'widgets/entrega_galeria_ux.dart';
import 'widgets/form_nueva_orden.dart';
import 'widgets/metricas_panel.dart';
import 'widgets/orden_card.dart';
import 'widgets/seccion_paso.dart';

/// Vista del flujo "Orden de trabajo" (3 pasos numerados).
///
/// Widget "dumb": sólo renderiza el estado expuesto por [OrdenesViewModel]
/// mediante [ListenableBuilder].
class OrdenesView extends StatelessWidget {
  const OrdenesView({
    super.key,
    required this.viewModel,
    this.mostrarAppBar = true,
  });

  final OrdenesViewModel viewModel;
  final bool mostrarAppBar;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: mostrarAppBar
              ? AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  title: Row(
                    children: [
                      const Icon(Icons.assignment_turned_in, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        viewModel.ordenSeleccionada == null
                            ? 'Órdenes de trabajo'
                            : 'Orden: ${viewModel.ordenSeleccionada!.nombreProyecto}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2B303A),
                        ),
                      ),
                    ],
                  ),
                  leading: viewModel.ordenSeleccionada != null
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: viewModel.volverALista,
                        )
                      : null,
                )
              : null,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (viewModel.error != null) _BannerError(viewModel),
                    if (viewModel.aviso != null) _BannerAviso(viewModel),

                    // ── Barra de Navegación / Breadcrumb cuando está en una orden ──
                    if (viewModel.ordenSeleccionada != null) ...[
                      _buildBreadcrumb(context),
                      const SizedBox(height: 18),
                    ],

                    if (viewModel.ordenSeleccionada != null)
                      _buildWizard(context)
                    else
                      _buildLista(context),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Barra de Ruta y Retorno (Breadcrumbs & Dashboard Return) ──────

  Widget _buildBreadcrumb(BuildContext context) {
    final orden = viewModel.ordenSeleccionada!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: viewModel.volverALista,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.dashboard_outlined, size: 18, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Dashboard de Órdenes',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              orden.nombreProyecto,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
                fontSize: 13.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => DialogEditarOrden.mostrar(
              context,
              orden: orden,
              viewModel: viewModel,
            ),
            icon: const Icon(Icons.edit_note, size: 18),
            label: const Text('Corregir orden'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Lista + formulario (Dashboard de órdenes) ─────────────────────

  Widget _buildLista(BuildContext context) {
    if (viewModel.cargando && viewModel.ordenes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (viewModel.metricas != null) ...[
          MetricasPanel(metricas: viewModel.metricas!),
          const SizedBox(height: 24),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard de Solicitudes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Gestión y seguimiento de órdenes por lotes',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed:
                  viewModel.mostrandoFormulario ? null : viewModel.mostrarFormulario,
              icon: const Icon(Icons.add),
              label: const Text('Nueva orden'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (viewModel.mostrandoFormulario) ...[
          FormNuevaOrden(viewModel: viewModel),
          const SizedBox(height: 24),
        ],
        if (viewModel.ordenes.isEmpty && !viewModel.mostrandoFormulario)
          _ListaVacia(
            onCrear: viewModel.mostrarFormulario,
          )
        else
          ...viewModel.ordenes.map(
            (orden) => OrdenCard(
              orden: orden,
              onTap: () => viewModel.seleccionarOrden(orden.id),
              onEditar: () => DialogEditarOrden.mostrar(
                context,
                orden: orden,
                viewModel: viewModel,
              ),
              onEliminar: () => _confirmarEliminarOrden(context, orden),
            ),
          ),
      ],
    );
  }

  void _confirmarEliminarOrden(BuildContext context, Orden orden) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar esta orden?'),
        content: Text(
          'Se eliminará la orden "${orden.nombreProyecto}" y sus archivos procesados de la base de datos y Storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              viewModel.eliminarOrden(orden.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );
  }

  // ── Wizard 3 pasos (detalle de la orden) ─────────────────────────

  Widget _buildWizard(BuildContext context) {
    final orden = viewModel.ordenSeleccionada!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Paso 1: datos de la solicitud (evento de negocio) ──
        SeccionPaso(
          numero: 1,
          titulo: 'Datos de la solicitud',
          detalle: 'Evento de negocio: el cliente solicita el servicio',
          accion: OutlinedButton.icon(
            onPressed: () => DialogEditarOrden.mostrar(
              context,
              orden: orden,
              viewModel: viewModel,
            ),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Corregir datos'),
          ),
          child: _DatosOrden(orden: orden),
        ),
        const SizedBox(height: 20),

        // ── Paso 2: imágenes → rembg → Supabase Storage ──
        SeccionPaso(
          numero: 2,
          titulo: 'Imágenes del proyecto',
          detalle: viewModel.procesando
              ? '${orden.imagenesProcesadas} de ${orden.totalImagenes} procesadas'
                  ' · ${viewModel.pendientesEnCola} en cola…'
              : '${orden.imagenesProcesadas} de ${orden.totalImagenes} procesadas',
          accion: orden.estaEntregada
              ? null
              : ElevatedButton.icon(
                  onPressed: viewModel.agregarYProcesarImagenes,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Agregar más imágenes al lote'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (viewModel.archivos.isNotEmpty)
                ColaControlBar(viewModel: viewModel),
              if (viewModel.archivos.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Aún no se procesaron imágenes en esta orden.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else if (viewModel.vistaCuadricula)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 260,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 295,
                  ),
                  itemCount: viewModel.archivos.length,
                  itemBuilder: (context, index) {
                    final archivo = viewModel.archivos[index];
                    return ArchivoLoteCard(
                      archivo: archivo,
                      numero: index + 1,
                      onComparar: () => DialogCompararLote.mostrar(
                        context,
                        archivos: viewModel.archivos,
                        indiceInicial: index,
                        onDescargar: viewModel.descargarResultado,
                      ),
                      onDescargar: () => viewModel.descargarResultado(archivo),
                      onReintentar: () => viewModel.reintentarArchivo(archivo),
                      onQuitarDeCola: () => viewModel.quitarDeCola(archivo),
                    );
                  },
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: viewModel.archivos.length,
                  itemBuilder: (context, index) {
                    final archivo = viewModel.archivos[index];
                    return ArchivoItem(
                      archivo: archivo,
                      numero: index + 1,
                      onComparar: () => DialogCompararLote.mostrar(
                        context,
                        archivos: viewModel.archivos,
                        indiceInicial: index,
                        onDescargar: viewModel.descargarResultado,
                      ),
                      onReintentar: () => viewModel.reintentarArchivo(archivo),
                      onDescargar: () => viewModel.descargarResultado(archivo),
                      onQuitarDeCola: () => viewModel.quitarDeCola(archivo),
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Paso 3: entrega + resultado medible con UX renovada ──
        SeccionPaso(
          numero: 3,
          titulo: 'Entrega y catálogo de resultados',
          detalle: 'Resultado medible del proceso E2E y auditoría de calidad',
          child: EntregaGaleriaUx(viewModel: viewModel),
        ),
      ],
    );
  }
}

// ── Widgets internos ────────────────────────────────────────────────

class _DatosOrden extends StatelessWidget {
  const _DatosOrden({required this.orden});

  final Orden orden;

  @override
  Widget build(BuildContext context) {
    final estiloEtiqueta = const TextStyle(color: AppColors.textSecondary);
    final estiloValor = const TextStyle(
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );

    return Wrap(
      spacing: 40,
      runSpacing: 12,
      children: [
        _campo('Proyecto', orden.nombreProyecto, estiloEtiqueta, estiloValor),
        _campo('Cliente', orden.clienteNombre, estiloEtiqueta, estiloValor),
        _campo('Contacto', orden.clienteEmail, estiloEtiqueta, estiloValor),
        _campo(
          'Estado',
          orden.estado.toString().split('.').last.toUpperCase(),
          estiloEtiqueta,
          estiloValor,
        ),
        _campo(
          'Creada',
          orden.createdAt.toString().substring(0, 16).replaceFirst('T', ' '),
          estiloEtiqueta,
          estiloValor,
        ),
      ],
    );
  }

  Widget _campo(String etiqueta, String valor, TextStyle e, TextStyle v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(etiqueta, style: e),
        const SizedBox(height: 2),
        Text(valor, style: v),
      ],
    );
  }
}


class _ListaVacia extends StatelessWidget {
  const _ListaVacia({required this.onCrear});

  final VoidCallback onCrear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const Icon(Icons.assignment_outlined,
              size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          const Text(
            'Todavía no hay órdenes de trabajo.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Crea la primera solicitud de servicio para iniciar el flujo.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onCrear,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Crear primera orden'),
          ),
        ],
      ),
    );
  }
}

class _BannerError extends StatelessWidget {
  const _BannerError(this.viewModel);

  final OrdenesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              viewModel.error!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
            onPressed: viewModel.limpiarError,
          ),
        ],
      ),
    );
  }
}

class _BannerAviso extends StatelessWidget {
  const _BannerAviso(this.viewModel);

  final OrdenesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              viewModel.aviso!,
              style: const TextStyle(color: Colors.green),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.green),
            onPressed: viewModel.limpiarAviso,
          ),
        ],
      ),
    );
  }
}
