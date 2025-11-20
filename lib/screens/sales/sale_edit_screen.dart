// v1.7 - screens/sales/sale_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/sales_service.dart';
import '../../services/customer_service.dart';
import '../../services/product_service.dart';
import '../../models/sale.dart';
import '../../models/sale_item.dart';
import '../../theme/app_colors.dart';

class SaleEditScreen extends StatefulWidget {
  final Sale sale;
  
  const SaleEditScreen({super.key, required this.sale});

  @override
  State<SaleEditScreen> createState() => _SaleEditScreenState();
}

class _SaleEditScreenState extends State<SaleEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late List<SaleItem> _saleItems;
  String _selectedPaymentType = 'Cash';
  String? _selectedCustomerId;

  @override
  void initState() {
    super.initState();
    _saleItems = List.from(widget.sale.items);
    _selectedPaymentType = widget.sale.paymentType;
    _selectedCustomerId = widget.sale.customerId;
  }

  double _calculateTotal() {
    return _saleItems.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  void _addProduct() {
    showDialog(
      context: context,
      builder: (context) => _AddProductDialog(
        onAdd: (item) {
          setState(() {
            _saleItems.add(item);
          });
        },
      ),
    );
  }

  void _editProduct(int index) {
    final item = _saleItems[index];
    showDialog(
      context: context,
      builder: (context) => _AddProductDialog(
        initialProductId: item.productId,
        initialQuantity: item.quantity,
        onAdd: (updatedItem) {
          setState(() {
            _saleItems[index] = updatedItem;
          });
        },
      ),
    );
  }

  void _removeProduct(int index) {
    setState(() {
      _saleItems.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final salesService = Provider.of<SalesService>(context, listen: false);
    final customerService = Provider.of<CustomerService>(context, listen: false);
    final productService = Provider.of<ProductService>(context, listen: false);

    final customers = customerService.customers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Venta'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _showDeleteDialog(context, salesService),
            tooltip: 'Eliminar venta',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Información de la venta original
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Información Original',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('ID: ${widget.sale.id}'),
                      Text('Fecha: ${widget.sale.date.day}/${widget.sale.date.month}/${widget.sale.date.year}'),
                      if (widget.sale.hasReceipt)
                        const Text('📄 Tiene comprobante adjunto'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Cliente
              DropdownButtonFormField<String>(
                value: _selectedCustomerId,
                decoration: const InputDecoration(
                  labelText: 'Cliente',
                  border: OutlineInputBorder(),
                ),
                items: [
                  // Opción para venta anónima
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Venta Anónima'),
                  ),
                  // Clientes registrados (solo IDs no nulos)
                  ...customers.where((customer) => customer.id != null).map((customer) {
                    return DropdownMenuItem<String>(
                      value: customer.id,
                      child: Text(customer.name.isNotEmpty ? customer.name : 'Cliente ${customer.id}'),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCustomerId = value;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Lista de productos
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Productos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _addProduct,
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_saleItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              'No hay productos agregados.\nPresiona "Agregar" para comenzar.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ...List.generate(_saleItems.length, (index) {
                          final item = _saleItems[index];
                          final product = productService.getById(item.productId);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: Text('${index + 1}'),
                              ),
                              title: Text(product?.name ?? 'Producto desconocido'),
                              subtitle: Text(
                                'Cantidad: ${item.quantity} x \$${item.unitPrice.toStringAsFixed(0)} = \$${item.subtotal.toStringAsFixed(0)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _editProduct(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removeProduct(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      if (_saleItems.isNotEmpty) ...[
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '\$${_calculateTotal().toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Método de pago
              DropdownButtonFormField<String>(
                value: _selectedPaymentType,
                decoration: const InputDecoration(
                  labelText: 'Método de Pago',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Cash', child: Text('Efectivo')),
                  DropdownMenuItem(value: 'Nequi', child: Text('Nequi')),
                  DropdownMenuItem(value: 'Pending', child: Text('Pendiente')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentType = value!;
                  });
                },
                validator: (value) => value == null ? 'Seleccione un método de pago' : null,
              ),
              
              const SizedBox(height: 24),
              
              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saleItems.isEmpty
                          ? null
                          : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                      ),
                      child: const Text('Guardar Cambios'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      if (_saleItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debe agregar al menos un producto'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final salesService = Provider.of<SalesService>(context, listen: false);
      
      final updatedSale = Sale(
        id: widget.sale.id,
        date: widget.sale.date,
        customerId: _selectedCustomerId,
        items: _saleItems,
        paymentType: _selectedPaymentType,
        paymentReceipt: widget.sale.paymentReceipt, // Mantener el comprobante original
      );
      
      salesService.updateSale(updatedSale);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Venta actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
    }
  }

  void _showDeleteDialog(BuildContext context, SalesService salesService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🗑️ Eliminar Venta'),
        content: const Text('¿Estás seguro de que quieres eliminar esta venta? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (widget.sale.id != null) {
                salesService.deleteSale(widget.sale.id!);
                Navigator.pop(context); // Cerrar diálogo
                Navigator.pop(context); // Volver a la lista de ventas
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🗑️ Venta eliminada'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// Diálogo para agregar/editar productos
class _AddProductDialog extends StatefulWidget {
  final String? initialProductId;
  final int? initialQuantity;
  final Function(SaleItem) onAdd;

  const _AddProductDialog({
    this.initialProductId,
    this.initialQuantity,
    required this.onAdd,
  });

  @override
  State<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<_AddProductDialog> {
  String? selectedProductId;
  int quantity = 1;
  final _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedProductId = widget.initialProductId;
    quantity = widget.initialQuantity ?? 1;
    _quantityController.text = quantity.toString();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productService = Provider.of<ProductService>(context, listen: false);
    final product = selectedProductId != null
        ? productService.getById(selectedProductId!)
        : null;

    return AlertDialog(
      title: Text(widget.initialProductId == null ? 'Agregar Producto' : 'Editar Producto'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedProductId,
              isExpanded: true,
              items: productService.products
                  .where((p) => p.stock > 0)
                  .map((p) => DropdownMenuItem<String>(
                value: p.id,
                child: Text(
                  '${p.name} (\$${p.price.toStringAsFixed(0)}) - Stock: ${p.stock}',
                  overflow: TextOverflow.ellipsis,
                ),
              ))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  selectedProductId = v;
                  if (product != null && product.stock < quantity) {
                    quantity = product.stock;
                    _quantityController.text = quantity.toString();
                  }
                });
              },
              decoration: const InputDecoration(
                labelText: 'Producto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                setState(() {
                  quantity = int.tryParse(v) ?? 1;
                });
              },
            ),
            if (product != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:'),
                    Text(
                      '\$${(product.price * quantity).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: selectedProductId == null
              ? null
              : () {
                  if (product != null) {
                    final item = SaleItem(
                      productId: selectedProductId!,
                      quantity: quantity,
                      unitPrice: product.price,
                    );
                    widget.onAdd(item);
                    Navigator.pop(context);
                  }
                },
          child: Text(widget.initialProductId == null ? 'Agregar' : 'Actualizar'),
        ),
      ],
    );
  }
}
