import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/venta_model.dart';
import '../../controllers/sales_controller.dart';
import '../../services/upload_image.dart';

class UploadEvidenceDialog extends StatefulWidget {
  final VentaModel venta;
  final SalesController controller;
  final Function setState;

  const UploadEvidenceDialog({
    super.key,
    required this.venta,
    required this.controller,
    required this.setState,
  });

  @override
  State<UploadEvidenceDialog> createState() => _UploadEvidenceDialogState();
}

class _UploadEvidenceDialogState extends State<UploadEvidenceDialog> {
  bool isProcessing = false;
  String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Subir evidencia de envío'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Venta #${widget.venta.id.substring(0, 6)}... - ${widget.venta.nombreCliente ?? 'Cliente general'}',
          ),
          const SizedBox(height: 16),

          // Si ya hay una evidencia de envío, mostrarla
          if (widget.venta.evidenciaEnvio != null &&
              widget.venta.evidenciaEnvio!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Evidencia actual:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.network(
                    widget.venta.evidenciaEnvio!,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => const Center(
                          child: Text('Error al cargar la imagen'),
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Subir nueva evidencia:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

          const SizedBox(height: 8),

          // Si hay una imagen seleccionada pero aún no subida, mostrarla
          if (imageUrl != null)
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) =>
                        const Center(child: Text('Error al cargar la imagen')),
              ),
            ),

          const SizedBox(height: 16),

          // Botones para seleccionar imagen
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isProcessing ? null : _selectFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galería'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isProcessing ? null : _takePhoto,
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Cámara'),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text('CANCELAR'),
        ),
        if (isProcessing)
          const CircularProgressIndicator()
        else
          ElevatedButton(
            onPressed: imageUrl == null ? null : _saveEvidence,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('GUARDAR'),
          ),
      ],
    );
  }

  Future<void> _selectFromGallery() async {
    try {
      setState(() => isProcessing = true);

      // Usar el servicio correcto ImageUploadService en lugar de UploadImageService
      final result = await ImageUploadService.pickAndUploadImage(
        source: ImageSource.gallery,
      );

      if (result['success']) {
        setState(() {
          imageUrl = result['url'];
          isProcessing = false;
        });
      } else {
        setState(() => isProcessing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      setState(() => isProcessing = true);

      // Usar el servicio correcto ImageUploadService en lugar de UploadImageService
      final result = await ImageUploadService.pickAndUploadImage(
        source: ImageSource.camera,
      );

      if (result['success']) {
        setState(() {
          imageUrl = result['url'];
          isProcessing = false;
        });
      } else {
        setState(() => isProcessing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveEvidence() async {
    try {
      setState(() => isProcessing = true);

      await widget.controller.updateShippingEvidence(
        widget.venta.id,
        imageUrl!,
        widget.setState,
        context,
      );

      Navigator.of(context).pop();
    } catch (e) {
      setState(() => isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
