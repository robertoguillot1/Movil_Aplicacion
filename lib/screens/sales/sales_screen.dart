import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/sales_service.dart';
import '../../services/customer_service.dart';
import '../../services/product_service.dart';
import '../../models/customer.dart';
import 'sale_form.dart';
import 'sale_edit_screen.dart';
import '../../widgets/receipt_capture_widget.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  bool _showTodayOnly = true; // Por defecto mostrar solo hoy
  bool _isSelectionMode = false; // Modo de selección múltiple
  Set<String> _selectedSales = <String>{}; // IDs de ventas seleccionadas

  @override
  Widget build(BuildContext context) {
    final salesService = Provider.of<SalesService>(context);
    final customerService = Provider.of<CustomerService>(context);
    final productService = Provider.of<ProductService>(context);

    // Verificar si ha cambiado el día para actualizar las estadísticas
    salesService.checkDayChange();

    // Determinar qué ventas mostrar según el filtro seleccionado
    final salesToShow = _showTodayOnly ? salesService.todaySales : salesService.sales;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? 'Seleccionar Ventas (${_selectedSales.length})' : 'Movimientos'),
        actions: _isSelectionMode ? _buildSelectionActions(salesService) : _buildNormalActions(salesService),
      ),
      body: Column(
        children: [
          // Botones de filtro (solo cuando no está en modo selección)
          if (!_isSelectionMode)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _showTodayOnly = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _showTodayOnly ? Colors.pink : Colors.white,
                        foregroundColor: _showTodayOnly ? Colors.white : Colors.black,
                        side: BorderSide(
                          color: _showTodayOnly ? Colors.pink : Colors.grey.shade300,
                        ),
                      ),
                      child: const Text('Hoy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _showTodayOnly = false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !_showTodayOnly ? Colors.pink : Colors.white,
                        foregroundColor: !_showTodayOnly ? Colors.white : Colors.black,
                        side: BorderSide(
                          color: !_showTodayOnly ? Colors.pink : Colors.grey.shade300,
                        ),
                      ),
                      child: const Text('Más Movimientos'),
                    ),
                  ),
                ],
              ),
            ),
          // Estadísticas del día (solo cuando se muestra "Hoy" y no está en modo selección)
          if (_showTodayOnly && !_isSelectionMode) _buildTodayStats(salesService),
          // Lista de ventas
          Expanded(
            child: salesToShow.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              itemCount: salesToShow.length,
              itemBuilder: (context, i) {
                final sale = salesToShow[i];
                final customer = sale.customerId != null ? customerService.getById(sale.customerId!) : Customer.empty();
                final firstProduct = sale.items.isNotEmpty 
                    ? productService.getById(sale.items.first.productId) 
                    : null;
                final productCount = sale.items.length;

                return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: _isSelectionMode && _selectedSales.contains(sale.id) 
                ? Colors.blue.shade50 
                : null,
            child: ExpansionTile(
              leading: _isSelectionMode 
                ? Checkbox(
                    value: _selectedSales.contains(sale.id),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedSales.add(sale.id!);
                        } else {
                          _selectedSales.remove(sale.id);
                        }
                      });
                    },
                  )
                : CircleAvatar(
                    backgroundColor: sale.isPending ? Colors.orange : Colors.green,
                    child: Icon(
                      sale.isPending ? Icons.pending : Icons.check_circle,
                      color: Colors.white,
                    ),
                  ),
              title: Text(
                productCount == 1
                    ? '${firstProduct?.name ?? "Producto desconocido"}'
                    : '$productCount productos',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cliente: ${customer.name.isNotEmpty ? customer.name : "Venta Anónima"}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text(
                    'Total: \$${sale.total.toStringAsFixed(0)} | ${sale.quantity} unidades',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Row(
                    children: [
                      Icon(
                        sale.paymentType == 'Cash' ? Icons.money :
                        sale.paymentType == 'Nequi' ? Icons.phone_android :
                        Icons.pending,
                        size: 16,
                        color: sale.paymentType == 'Cash' ? Colors.green :
                               sale.paymentType == 'Nequi' ? Colors.blue :
                               Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        sale.paymentType,
                        style: TextStyle(
                          color: sale.paymentType == 'Cash' ? Colors.green :
                                 sale.paymentType == 'Nequi' ? Colors.blue :
                                 Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (sale.hasReceipt) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Comprobante',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mostrar icono de comprobante si existe
                  if (sale.hasReceipt)
                    IconButton(
                      icon: const Icon(Icons.receipt_long, color: Colors.blue),
                      onPressed: () => _showReceiptDialog(context, sale.paymentReceipt!),
                      tooltip: 'Ver comprobante',
                    ),
                  
                  // Menú de cambio de estado de pago
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (String newPaymentType) {
                      if (newPaymentType == 'Nequi' && !sale.hasReceipt) {
                        _showReceiptCaptureDialog(context, sale, salesService);
                      } else {
                        if (sale.id != null) {
                          salesService.updatePaymentStatus(sale.id!, newPaymentType);
                        }
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'Cash',
                        child: ListTile(
                          leading: Icon(Icons.money, color: Colors.green),
                          title: Text('Efectivo'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Nequi',
                        child: ListTile(
                          leading: Icon(Icons.phone_android, color: Colors.blue),
                          title: Text('Nequi'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Pending',
                        child: ListTile(
                          leading: Icon(Icons.pending, color: Colors.orange),
                          title: Text('Pendiente'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Información detallada
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info_outline, size: 20, color: Colors.blue),
                                const SizedBox(width: 8),
                                const Text(
                                  'Detalles de la Venta',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow('👤 Cliente', customer.name.isNotEmpty ? customer.name : "Venta Anónima"),
                            _buildDetailRow('📊 Total de Unidades', '${sale.quantity} unidades'),
                            _buildDetailRow('💵 Total', '\$${sale.total.toStringAsFixed(0)}'),
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 8),
                            const Text(
                              'Productos:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...sale.items.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              final product = productService.getById(item.productId);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Text('${index + 1}. ', style: TextStyle(color: Colors.grey.shade600)),
                                    Expanded(
                                      child: Text(
                                        '${product?.name ?? "Producto desconocido"}',
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    Text(
                                      '${item.quantity} x \$${item.unitPrice.toStringAsFixed(0)} = \$${item.subtotal.toStringAsFixed(0)}',
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            _buildDetailRow('📅 Fecha', '${sale.date.day}/${sale.date.month}/${sale.date.year}'),
                            _buildDetailRow('💳 Método de Pago', sale.paymentType),
                            if (sale.hasReceipt)
                              _buildDetailRow('📄 Comprobante', 'Disponible', isReceipt: true),
                          ],
                        ),
                      ),
                      
                      // Botones de acción
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (sale.hasReceipt)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showReceiptDialog(context, sale.paymentReceipt!),
                                icon: const Icon(Icons.receipt_long),
                                label: const Text('Ver Comprobante'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          if (sale.hasReceipt) const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SaleEditScreen(sale: sale),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Editar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNormalActions(SalesService salesService) {
    return [
      Consumer<SalesService>(
        builder: (context, salesService, child) {
          return IconButton(
            icon: salesService.isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.refresh),
            onPressed: salesService.isLoading ? null : () {
              salesService.refreshSales();
            },
            tooltip: 'Refrescar ventas',
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.select_all),
        onPressed: () {
          setState(() {
            _isSelectionMode = true;
            _selectedSales.clear();
          });
        },
        tooltip: 'Seleccionar ventas',
      ),
      IconButton(
        icon: const Icon(Icons.add_shopping_cart),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SaleFormScreen()),
        ),
        tooltip: 'Agregar venta',
      ),
    ];
  }

  List<Widget> _buildSelectionActions(SalesService salesService) {
    return [
      if (_selectedSales.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _showDeleteSelectedDialog(salesService),
          tooltip: 'Borrar seleccionadas',
        ),
      IconButton(
        icon: const Icon(Icons.delete_sweep),
        onPressed: () => _showDeleteAllDialog(salesService),
        tooltip: 'Borrar todas',
      ),
      IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          setState(() {
            _isSelectionMode = false;
            _selectedSales.clear();
          });
        },
        tooltip: 'Cancelar selección',
      ),
    ];
  }

  Widget _buildTodayStats(SalesService salesService) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade50, Colors.pink.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.pink.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.today, color: Colors.pink.shade600),
              const SizedBox(width: 8),
              Text(
                'Resumen del Día',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Ventas',
                  '${salesService.todaySalesCount}',
                  Icons.shopping_cart,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Ingresos',
                  '\$${salesService.todayRevenue.toStringAsFixed(0)}',
                  Icons.monetization_on,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Unidades',
                  '${salesService.todayUnitsSold}',
                  Icons.inventory,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _showTodayOnly 
              ? 'Hoy no has hecho ningún movimiento.'
              : 'No hay ventas registradas',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _showTodayOnly 
              ? 'Las ventas del día aparecerán aquí'
              : 'Las ventas aparecerán aquí cuando registres alguna',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog(SalesService salesService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('⚠️ Confirmar Borrado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Estás seguro de que quieres borrar TODAS las ventas?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Esta acción:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('• Borrará ${salesService.sales.length} ventas'),
                  const Text('• No se puede deshacer'),
                  const Text('• Eliminará todo el historial'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await salesService.deleteAllSales();
              setState(() {
                _isSelectionMode = false;
                _selectedSales.clear();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('BORRAR TODAS'),
          ),
        ],
      ),
    );
  }

  void _showDeleteSelectedDialog(SalesService salesService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('⚠️ Confirmar Borrado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que quieres borrar ${_selectedSales.length} ventas seleccionadas?',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Esta acción:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('• Borrará ${_selectedSales.length} ventas'),
                  const Text('• No se puede deshacer'),
                  const Text('• Las ventas restantes se mantendrán'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await salesService.deleteSelectedSales(_selectedSales.toList());
              setState(() {
                _isSelectionMode = false;
                _selectedSales.clear();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('BORRAR SELECCIONADAS'),
          ),
        ],
      ),
    );
  }

  static Widget _buildDetailRow(String label, String value, {bool isReceipt = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: isReceipt
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '📄 Ver Comprobante',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
          ),
        ],
      ),
    );
  }

  static void _showReceiptDialog(BuildContext context, String receiptPath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Comprobante de Pago'),
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: kIsWeb 
                    ? _buildWebReceiptView(receiptPath)
                    : Image.file(
                        File(receiptPath),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, color: Colors.red, size: 64),
                                SizedBox(height: 16),
                                Text('Error al cargar el comprobante'),
                              ],
                            ),
                          );
                        },
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para mostrar información del comprobante en web
  static Widget _buildWebReceiptView(String receiptPath) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.blue.shade600,
          ),
          const SizedBox(height: 16),
          Text(
            'Comprobante Disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'El comprobante fue capturado desde el dispositivo móvil.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  'Ver desde la app móvil',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ruta: ${receiptPath.split('/').last}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static void _showReceiptCaptureDialog(BuildContext context, sale, SalesService salesService) {
    String? receiptPath;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('📷 Agregar Comprobante Nequi'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 400,
              maxHeight: 500,
            ),
            child: SingleChildScrollView(
              child: ReceiptCaptureWidget(
                onReceiptChanged: (path) {
                  receiptPath = path;
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                salesService.updatePaymentStatus(sale.id, 'Nequi', paymentReceipt: receiptPath);
                Navigator.pop(context);
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }
}
