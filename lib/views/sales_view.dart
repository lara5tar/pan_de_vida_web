import 'package:flutter/material.dart';
import '../controllers/sales_controller.dart';
import '../models/venta_model.dart';
import '../components/sales/sales_by_day_tab.dart';
import '../components/sales/pending_payments_tab.dart';
import '../components/sales/shipping_sales_tab.dart';
import '../components/sales/sale_details_dialog.dart';
import '../components/sales/register_payment_dialog.dart';
import '../components/sales/upload_evidence_dialog.dart';
import '../components/sales/shipping_evidence_dialog.dart';

class SalesView extends StatefulWidget {
  const SalesView({super.key});

  @override
  State<SalesView> createState() => _SalesViewState();
}

class _SalesViewState extends State<SalesView>
    with SingleTickerProviderStateMixin {
  final SalesController _controller = SalesController();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Establecer la fecha actual por defecto
    _controller.selectedDate = DateTime.now();

    // Cargar datos iniciales para la pestaña activa
    _controller.loadVentas(setState);

    _tabController.addListener(() {
      // Solo hacemos algo cuando el tab realmente cambia
      if (_tabController.indexIsChanging) {
        _controller.onTabChanged(_tabController.index, setState);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ventas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ventas por Día'),
            Tab(text: 'Pagos Pendientes'),
            Tab(text: 'Ventas con Envío'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/new-sale');
        },
        tooltip: 'Nueva Venta',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Mostrar mensaje de error si existe, pero siempre mostrar el contenido
          // if (_controller.errorMessage.isNotEmpty)
          //   Container(
          //     color: Colors.red.shade100,
          //     width: double.infinity,
          //     padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          //     child: Text(
          //       _controller.errorMessage,
          //       style: const TextStyle(color: Colors.red),
          //       textAlign: TextAlign.center,
          //     ),
          //   ),

          // Mostrar indicador de carga o contenido principal
          Expanded(
            child:
                _controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildSalesContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        // Pestaña de ventas por día
        SalesByDayTab(
          controller: _controller,
          setState: setState,
          onViewDetails: _showSaleDetails,
        ),

        // Pestaña de pagos pendientes
        PendingPaymentsTab(
          controller: _controller,
          setState: setState,
          onViewDetails: _showSaleDetails,
          onRegisterPayment: _showAddPaymentDialog,
          searchController: _searchController,
        ),

        // Pestaña de ventas con envío
        ShippingSalesTab(
          controller: _controller,
          setState: setState,
          onViewDetails: _showSaleDetails,
          onUploadEvidence: _showUploadEvidenceDialog,
          onViewEvidence: _showEvidenceImage,
          searchController: _searchController,
        ),
      ],
    );
  }

  void _showSaleDetails(VentaModel venta) {
    showDialog(
      context: context,
      builder:
          (context) => SaleDetailsDialog(venta: venta, controller: _controller),
    );
  }

  void _showAddPaymentDialog(VentaModel venta) {
    showDialog(
      context: context,
      builder:
          (context) => RegisterPaymentDialog(
            venta: venta,
            controller: _controller,
            setState: setState,
          ),
    );
  }

  void _showUploadEvidenceDialog(VentaModel venta) {
    showDialog(
      context: context,
      builder:
          (context) => UploadEvidenceDialog(
            venta: venta,
            controller: _controller,
            setState: setState,
          ),
    );
  }

  void _showEvidenceImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => ShippingEvidenceDialog(imageUrl: imageUrl),
    );
  }
}
