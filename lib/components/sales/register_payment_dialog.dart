import 'package:flutter/material.dart';
import '../../models/venta_model.dart';
import '../../controllers/sales_controller.dart';

class RegisterPaymentDialog extends StatefulWidget {
  final VentaModel venta;
  final SalesController controller;
  final Function setState;

  const RegisterPaymentDialog({
    super.key,
    required this.venta,
    required this.controller,
    required this.setState,
  });

  @override
  State<RegisterPaymentDialog> createState() => _RegisterPaymentDialogState();
}

class _RegisterPaymentDialogState extends State<RegisterPaymentDialog> {
  final montoController = TextEditingController();
  final comentariosController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isProcessing = false;

  @override
  void dispose() {
    montoController.dispose();
    comentariosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar nuevo pago'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cliente: ${widget.venta.nombreCliente ?? 'Cliente general'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Monto pendiente: \$${widget.venta.totalPendiente.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: montoController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto a pagar',
                hintText: 'Ingrese el monto del pago',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese un monto';
                }
                final monto = double.tryParse(value);
                if (monto == null) {
                  return 'Ingrese un monto válido';
                }
                if (monto <= 0) {
                  return 'El monto debe ser mayor a cero';
                }
                if (monto > widget.venta.totalPendiente) {
                  return 'El monto no puede ser mayor al pendiente';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: comentariosController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Comentarios (opcional)',
                hintText: 'Ingrese comentarios sobre el pago',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCELAR'),
        ),
        if (isProcessing)
          const CircularProgressIndicator()
        else
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                setState(() {
                  isProcessing = true;
                });

                final monto = double.parse(montoController.text);
                final comentarios = comentariosController.text;

                await widget.controller.registerPayment(
                  widget.venta,
                  monto,
                  comentarios,
                  widget.setState,
                  context,
                );

                // Si no se ha cerrado el diálogo manualmente, cerrarlo
                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('REGISTRAR PAGO'),
          ),
      ],
    );
  }
}
