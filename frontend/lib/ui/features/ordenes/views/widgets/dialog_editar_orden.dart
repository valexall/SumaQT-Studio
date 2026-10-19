import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../domain/models/orden.dart';
import '../../view_models/ordenes_view_model.dart';

/// Modal para corregir los datos de una orden (nombre del proyecto, cliente, email)
/// o eliminarla si fue creada por error.
class DialogEditarOrden extends StatefulWidget {
  const DialogEditarOrden({
    super.key,
    required this.orden,
    required this.viewModel,
  });

  final Orden orden;
  final OrdenesViewModel viewModel;

  static Future<void> mostrar(
    BuildContext context, {
    required Orden orden,
    required OrdenesViewModel viewModel,
  }) {
    return showDialog(
      context: context,
      builder: (_) => DialogEditarOrden(orden: orden, viewModel: viewModel),
    );
  }

  @override
  State<DialogEditarOrden> createState() => _DialogEditarOrdenState();
}

class _DialogEditarOrdenState extends State<DialogEditarOrden> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _proyectoCtrl;
  late final TextEditingController _clienteCtrl;
  late final TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    _proyectoCtrl = TextEditingController(text: widget.orden.nombreProyecto);
    _clienteCtrl = TextEditingController(text: widget.orden.clienteNombre);
    _emailCtrl = TextEditingController(text: widget.orden.clienteEmail);
  }

  @override
  void dispose() {
    _proyectoCtrl.dispose();
    _clienteCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.edit_note, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text(
            'Corregir datos de la orden',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _proyectoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del proyecto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.folder_outlined),
                ),
                validator: (val) => (val == null || val.trim().length < 3)
                    ? 'Mínimo 3 caracteres'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _clienteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del cliente',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) => (val == null || val.trim().length < 2)
                    ? 'Mínimo 2 caracteres'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email de contacto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (val) {
                  final v = (val ?? '').trim();
                  return RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$').hasMatch(v)
                      ? null
                      : 'Email inválido';
                },
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      actions: [
        TextButton.icon(
          onPressed: _confirmarEliminar,
          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
          label: const Text('Eliminar orden', style: TextStyle(color: Colors.red)),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Guardar cambios'),
        ),
      ],
    );
  }

  void _guardar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop();
    widget.viewModel.editarOrden(
      ordenId: widget.orden.id,
      nombreProyecto: _proyectoCtrl.text.trim(),
      clienteNombre: _clienteCtrl.text.trim(),
      clienteEmail: _emailCtrl.text.trim(),
    );
  }

  void _confirmarEliminar() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar esta orden?'),
        content: Text(
          'Se eliminará la orden "${widget.orden.nombreProyecto}" y sus imágenes asociadas. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Cierra confirmación
              Navigator.of(context).pop(); // Cierra diálogo edición
              widget.viewModel.eliminarOrden(widget.orden.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );
  }
}
