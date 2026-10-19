import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../data/services/file_picker_service.dart';
import '../../view_models/ordenes_view_model.dart';

/// Formulario del paso 1: datos de la solicitud del cliente.
/// La cantidad de imágenes se define al seleccionarlas (no con un número).
class FormNuevaOrden extends StatefulWidget {
  const FormNuevaOrden({super.key, required this.viewModel});

  final OrdenesViewModel viewModel;

  @override
  State<FormNuevaOrden> createState() => _FormNuevaOrdenState();
}

class _FormNuevaOrdenState extends State<FormNuevaOrden> {
  final _formKey = GlobalKey<FormState>();
  final _proyectoController = TextEditingController();
  final _clienteController = TextEditingController();
  final _emailController = TextEditingController();
  final List<ArchivoSeleccionado> _imagenes = [];

  @override
  void dispose() {
    _proyectoController.dispose();
    _clienteController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nueva solicitud de servicio',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 280,
                  child: TextFormField(
                    controller: _proyectoController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del proyecto *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) => (valor == null || valor.trim().length < 3)
                        ? 'Mínimo 3 caracteres'
                        : null,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextFormField(
                    controller: _clienteController,
                    decoration: const InputDecoration(
                      labelText: 'Cliente *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) => (valor == null || valor.trim().length < 2)
                        ? 'Mínimo 2 caracteres'
                        : null,
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email del cliente *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      final v = (valor ?? '').trim();
                      final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$');
                      return regex.hasMatch(v) ? null : 'Email inválido';
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _seleccionarImagenes,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(_imagenes.isEmpty
                      ? 'Seleccionar imágenes *'
                      : 'Imágenes seleccionadas: ${_imagenes.length}'),
                ),
                if (_imagenes.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      setState(() => _imagenes.clear());
                    },
                    child: const Text('Vaciar'),
                  ),
                ],
              ],
            ),
            if (_imagenes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _imagenes
                    .map(
                      (img) => Chip(
                        avatar: const Icon(Icons.image, size: 18),
                        label: Text(img.nombre, overflow: TextOverflow.ellipsis),
                        onDeleted: () => setState(() => _imagenes.remove(img)),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: widget.viewModel.enviando
                      ? null
                      : _enviar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                  ),
                  child: widget.viewModel.enviando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Crear orden'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: widget.viewModel.ocultarFormulario,
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seleccionarImagenes() async {
    final seleccion = await widget.viewModel.seleccionarImagenesParaFormulario();
    if (seleccion.isEmpty) return;
    setState(() => _imagenes.addAll(seleccion));
  }

  void _enviar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_imagenes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos una imagen para la solicitud.'),
        ),
      );
      return;
    }
    widget.viewModel.crearOrden(
      nombreProyecto: _proyectoController.text.trim(),
      clienteNombre: _clienteController.text.trim(),
      clienteEmail: _emailController.text.trim(),
      imagenes: _imagenes,
    );
  }
}
