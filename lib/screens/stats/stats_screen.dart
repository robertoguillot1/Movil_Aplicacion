import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/stats_service.dart';
import '../../services/product_service.dart';
import '../../services/sales_service.dart';
import '../../services/customer_service.dart';
import '../../models/customer.dart';
import '../../widgets/stat_card.dart';
import '../../models/sale.dart';
import '../../utils/excel_generator.dart';
import '../../utils/pdf_generator.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String selectedFilter = 'Hoy'; // Cambiar por defecto a "Hoy"
  String selectedPaymentMethod = 'Todos';
  DateTimeRange? dateRange;

  @override
  Widget build(BuildContext context) {
    final statsService = Provider.of<StatsService>(context);
    final productService = Provider.of<ProductService>(context);
    final salesService = Provider.of<SalesService>(context);
    final customerService = Provider.of<CustomerService>(context);

    // Filtrar ventas según los filtros seleccionados
    List<Sale> filteredSales;
    
    // Determinar qué ventas usar según el filtro seleccionado
    if (selectedFilter == 'Hoy') {
      filteredSales = salesService.todaySales;
    } else if (selectedFilter == 'Todos') {
      filteredSales = salesService.sales;
    } else if (selectedFilter == 'Personalizado' && dateRange != null) {
      filteredSales = salesService.sales.where((s) => 
        s.date.isAfter(dateRange!.start.subtract(const Duration(days: 1))) &&
        s.date.isBefore(dateRange!.end.add(const Duration(days: 1)))
      ).toList();
    } else {
      filteredSales = salesService.sales;
    }
    
    // Aplicar filtro de método de pago
    if (selectedPaymentMethod != 'Todos') {
      filteredSales = filteredSales.where((s) => s.paymentType == selectedPaymentMethod).toList();
    }

    // Calcular estadísticas filtradas
    final filteredRevenue = filteredSales.fold(0.0, (sum, sale) => sum + sale.total);
    final filteredUnitsSold = filteredSales.fold(0, (sum, sale) => sum + sale.quantity);
    final pendingPayments = filteredSales.where((s) => s.isPending).length;
    final paidPayments = filteredSales.where((s) => !s.isPending).length;

    // Estadísticas por método de pago
    final paymentStats = <String, double>{};
    for (var sale in filteredSales) {
      paymentStats[sale.paymentType] = (paymentStats[sale.paymentType] ?? 0) + sale.total;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Estadísticas Avanzadas'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _showExportDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          statsService.refresh();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filtros activos
              if (selectedFilter != 'Todos' || selectedPaymentMethod != 'Todos' || (selectedFilter == 'Personalizado' && dateRange != null))
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🔍 Filtros Activos:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (selectedFilter == 'Hoy')
                              Chip(
                                label: const Text('Período: Hoy'),
                                backgroundColor: Colors.pink.shade100,
                                deleteIconColor: Colors.pink.shade700,
                                onDeleted: () => setState(() => selectedFilter = 'Todos'),
                              ),
                            if (selectedPaymentMethod != 'Todos')
                              Chip(
                                label: Text('Pago: $selectedPaymentMethod'),
                                onDeleted: () => setState(() => selectedPaymentMethod = 'Todos'),
                              ),
                            if (selectedFilter == 'Personalizado' && dateRange != null)
                              Chip(
                                label: Text('Fecha: ${dateRange!.start.day}/${dateRange!.start.month} - ${dateRange!.end.day}/${dateRange!.end.month}'),
                                onDeleted: () => setState(() => dateRange = null),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Mostrando ${filteredSales.length} ventas de ${salesService.sales.length} totales'),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Tarjetas de estadísticas principales
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: '💰 Ingresos',
                      value: '\$${filteredRevenue.toStringAsFixed(0)}',
                      icon: Icons.monetization_on,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatCard(
                      title: '📦 Unidades',
                      value: '$filteredUnitsSold',
                      icon: Icons.shopping_cart,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: '✅ Pagados',
                      value: '$paidPayments',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatCard(
                      title: '⏳ Pendientes',
                      value: '$pendingPayments',
                      icon: Icons.pending,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Estadísticas por método de pago
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💳 Ventas por Método de Pago',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (paymentStats.isEmpty)
                        const Text('No hay ventas en el período seleccionado')
                      else
                        ...paymentStats.entries.map((entry) {
                          final percentage = filteredRevenue > 0 ? (entry.value / filteredRevenue * 100) : 0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(_getPaymentMethodName(entry.key)),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: LinearProgressIndicator(
                                    value: percentage / 100,
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _getPaymentMethodColor(entry.key),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '\$${entry.value.toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 4),
                                Text('(${percentage.toStringAsFixed(1)}%)'),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Deudas pendientes
              Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.money_off, color: Colors.red),
                  title: const Text('💸 Deudas Pendientes'),
                  subtitle: Text('${pendingPayments} ventas pendientes'),
                  children: pendingPayments == 0
                      ? [const ListTile(title: Text('✅ No hay deudas pendientes'))]
                      : filteredSales.where((s) => s.isPending).map((sale) {
                          final firstProduct = sale.items.isNotEmpty 
                              ? productService.getById(sale.items.first.productId) 
                              : null;
                          final customer = sale.customerId != null ? customerService.getById(sale.customerId!) : Customer.empty();
                          final productCount = sale.items.length;
                          final productName = productCount == 1
                              ? (firstProduct?.name ?? 'Producto desconocido')
                              : '$productCount productos';
                          return ListTile(
                            leading: const Icon(Icons.pending, color: Colors.orange),
                            title: Text(productName),
                            subtitle: Text(
                              'Cliente: ${customer.name.isNotEmpty ? customer.name : "Anónimo"}\n'
                              'Fecha: ${sale.date.day}/${sale.date.month}/${sale.date.year}',
                            ),
                            trailing: Text(
                              '\$${sale.total.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                          );
                        }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Productos más vendidos
              Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.bar_chart, color: Colors.green),
                  title: const Text('🏆 Productos más Vendidos'),
                  subtitle: Text('${statsService.revenueByProduct.length} productos'),
                  children: statsService.revenueByProduct.isEmpty
                      ? [const ListTile(title: Text('📈 Aún no hay ventas registradas'))]
                      : (() {
                          final sortedEntries = statsService.revenueByProduct.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value));
                          return sortedEntries.take(5).map((entry) => ListTile(
                                leading: const Icon(Icons.trending_up),
                                title: Text(entry.key),
                                subtitle: Text('Ingresos: \$${entry.value.toStringAsFixed(0)}'),
                              )).toList();
                        })(),
                ),
              ),
              const SizedBox(height: 16),

              // Valor del inventario
              Card(
                child: ListTile(
                  leading: const Icon(Icons.warehouse, color: Colors.indigo),
                  title: const Text('Valor del Inventario'),
                  subtitle: Text('\$${statsService.totalInventoryValue.toStringAsFixed(0)}'),
                  trailing: Text('Precio promedio: \$${statsService.averageProductPrice.toStringAsFixed(0)}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔍 Filtrar Estadísticas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedFilter,
              decoration: const InputDecoration(labelText: 'Período'),
              items: const [
                DropdownMenuItem(value: 'Hoy', child: Text('Hoy')),
                DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                DropdownMenuItem(value: 'Personalizado', child: Text('Personalizado')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedFilter = value!;
                  if (value != 'Personalizado') {
                    dateRange = null;
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedPaymentMethod,
              decoration: const InputDecoration(labelText: 'Método de Pago'),
              items: const [
                DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                DropdownMenuItem(value: 'Cash', child: Text('Efectivo')),
                DropdownMenuItem(value: 'Nequi', child: Text('Nequi')),
                DropdownMenuItem(value: 'Pending', child: Text('Pendiente')),
              ],
              onChanged: (value) => setState(() => selectedPaymentMethod = value!),
            ),
            const SizedBox(height: 16),
            if (selectedFilter == 'Personalizado')
              ElevatedButton.icon(
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (range != null) {
                    setState(() => dateRange = range);
                  }
                },
                icon: const Icon(Icons.date_range),
                label: Text(dateRange == null ? 'Seleccionar Fechas' : 'Cambiar Fechas'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                selectedFilter = 'Hoy';
                selectedPaymentMethod = 'Todos';
                dateRange = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Limpiar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'Cash': return 'Efectivo';
      case 'Nequi': return 'Nequi';
      case 'Pending': return 'Pendiente';
      default: return method;
    }
  }

  Color _getPaymentMethodColor(String method) {
    switch (method) {
      case 'Cash': return Colors.green;
      case 'Nequi': return Colors.blue;
      case 'Pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📄 Exportar Reporte'),
        content: const Text('Selecciona cómo quieres exportar tu reporte:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          // Opciones para CSV
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showCsvOptions(context);
            },
            icon: const Icon(Icons.table_chart),
            label: const Text('CSV'),
          ),
          // Opciones para TXT
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showTxtOptions(context);
            },
            icon: const Icon(Icons.description),
            label: const Text('TXT'),
          ),
        ],
      ),
    );
  }

  void _showCsvOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📊 Exportar CSV'),
        content: const Text('¿Cómo quieres exportar tu reporte CSV?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _saveCsvToDevice(context);
            },
            icon: const Icon(Icons.save),
            label: const Text('Guardar en dispositivo'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _shareCsv(context);
            },
            icon: const Icon(Icons.share),
            label: const Text('Compartir'),
          ),
        ],
      ),
    );
  }

  void _showTxtOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📄 Exportar TXT'),
        content: const Text('¿Cómo quieres exportar tu reporte TXT?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _saveTxtToDevice(context);
            },
            icon: const Icon(Icons.save),
            label: const Text('Guardar en dispositivo'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _shareTxt(context);
            },
            icon: const Icon(Icons.share),
            label: const Text('Compartir'),
          ),
        ],
      ),
    );
  }

  void _saveCsvToDevice(BuildContext context) async {
    final salesService = Provider.of<SalesService>(context, listen: false);
    final productService = Provider.of<ProductService>(context, listen: false);
    final customerService = Provider.of<CustomerService>(context, listen: false);
    
    try {
      final file = await ExcelGenerator.generateAndSaveExcel(
        salesService.sales,
        customerService,
        productService,
      );
      
      if (file != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Reporte CSV listo para guardar/compartir'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareCsv(BuildContext context) async {
    final salesService = Provider.of<SalesService>(context, listen: false);
    final productService = Provider.of<ProductService>(context, listen: false);
    final customerService = Provider.of<CustomerService>(context, listen: false);
    
    try {
      await ExcelGenerator.shareExcel(
        salesService.sales,
        customerService,
        productService,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Reporte CSV listo para compartir'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al compartir: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _saveTxtToDevice(BuildContext context) async {
    final salesService = Provider.of<SalesService>(context, listen: false);
    final productService = Provider.of<ProductService>(context, listen: false);
    final customerService = Provider.of<CustomerService>(context, listen: false);
    
    try {
      final file = await PdfGenerator.generateAndSavePdf(
        salesService.sales,
        customerService,
        productService,
      );
      
      if (file != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Reporte TXT listo para guardar/compartir'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareTxt(BuildContext context) async {
    final salesService = Provider.of<SalesService>(context, listen: false);
    final productService = Provider.of<ProductService>(context, listen: false);
    final customerService = Provider.of<CustomerService>(context, listen: false);
    
    try {
      await PdfGenerator.sharePdf(
        salesService.sales,
        customerService,
        productService,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Reporte TXT listo para compartir'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al compartir: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
