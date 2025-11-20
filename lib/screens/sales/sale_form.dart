import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/sales_service.dart';
import '../../services/product_service.dart';
import '../../services/customer_service.dart';
import '../../models/sale_item.dart';
import '../../widgets/receipt_capture_widget.dart';

class SaleFormScreen extends StatefulWidget {
  const SaleFormScreen({super.key});

  @override
  State<SaleFormScreen> createState() => _SaleFormScreenState();
}

class _SaleFormScreenState extends State<SaleFormScreen> {
  final List<SaleItem> _saleItems = [];
  String? selectedCustomerId;
  String paymentType = 'Cash';
  bool isAnonymousSale = false;
  String? paymentReceipt;
  final _formKey = GlobalKey<FormState>();
  
  // Variables para cálculo de cambio
  final TextEditingController _cashReceivedController = TextEditingController();
  double? _changeAmount;

  @override
  void dispose() {
    _cashReceivedController.dispose();
    super.dispose();
  }

  // Calcular el total de la venta
  double _calculateTotal() {
    return _saleItems.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  // Calcular el cambio
  void _calculateChange() {
    final cashReceived = double.tryParse(_cashReceivedController.text) ?? 0.0;
    final total = _calculateTotal();
    setState(() {
      _changeAmount = cashReceived - total;
    });
  }

  void _addProduct() {
    showDialog(
      context: context,
      builder: (context) => _AddProductDialog(
        onAdd: (item) {
          setState(() {
            _saleItems.add(item);
            _calculateChange();
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
            _calculateChange();
          });
        },
      ),
    );
  }

  void _removeProduct(int index) {
    setState(() {
      _saleItems.removeAt(index);
      _calculateChange();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productService = Provider.of<ProductService>(context);
    final customerService = Provider.of<CustomerService>(context);
    final salesService = Provider.of<SalesService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Venta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              
              // Opción de venta anónima
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_outline, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          const Text(
                            'Selección de Cliente',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: const Text('Venta Anónima'),
                        subtitle: const Text('No asignar a ningún cliente específico'),
                        value: isAnonymousSale,
                        onChanged: (value) {
                          setState(() {
                            isAnonymousSale = value ?? false;
                            if (isAnonymousSale) {
                              selectedCustomerId = null;
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (!isAnonymousSale) ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedCustomerId,
                          items: customerService.customers
                              .map((c) => DropdownMenuItem<String>(
                            value: c.id,
                            child: Text(c.name),
                          ))
                              .toList(),
                          onChanged: (v) => setState(() => selectedCustomerId = v),
                          decoration: const InputDecoration(
                            labelText: 'Seleccionar Cliente',
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (v) => !isAnonymousSale && v == null ? 'Seleccione un cliente' : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Método de pago
              DropdownButtonFormField<String>(
                value: paymentType,
                items: const [
                  DropdownMenuItem(value: 'Cash', child: Text('Efectivo')),
                  DropdownMenuItem(value: 'Nequi', child: Text('Nequi')),
                  DropdownMenuItem(value: 'Pending', child: Text('Pendiente')),
                ],
                onChanged: (v) {
                  setState(() {
                    paymentType = v ?? 'Cash';
                    if (paymentType != 'Cash') {
                      _cashReceivedController.clear();
                      _changeAmount = null;
                    }
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Método de Pago',
                  prefixIcon: Icon(Icons.payment),
                ),
              ),
              
              // Calculadora de cambio para efectivo
              if (paymentType == 'Cash' && _saleItems.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calculate, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              'Calculadora de Cambio',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Mostrar total
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total a pagar:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '\$${_calculateTotal().toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Campo para dinero recibido
                        TextFormField(
                          controller: _cashReceivedController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Dinero recibido',
                            prefixIcon: Icon(Icons.money),
                            hintText: 'Ingrese la cantidad que le dieron',
                          ),
                          onChanged: (value) => _calculateChange(),
                        ),
                        const SizedBox(height: 12),
                        
                        // Mostrar cambio
                        if (_changeAmount != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _changeAmount! >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _changeAmount! >= 0 ? Colors.green.shade200 : Colors.red.shade200,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _changeAmount! >= 0 ? 'Cambio a dar:' : 'Falta dinero:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _changeAmount! >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                ),
                                Text(
                                  '\$${_changeAmount!.abs().toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _changeAmount! >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_changeAmount! < 0) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.orange.shade700, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'El cliente no ha dado suficiente dinero',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              
              // Comprobante de pago para Nequi
              if (paymentType == 'Nequi') ...[
                const SizedBox(height: 16),
                ReceiptCaptureWidget(
                  initialReceiptPath: paymentReceipt,
                  onReceiptChanged: (receiptPath) {
                    setState(() => paymentReceipt = receiptPath);
                  },
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Registrar Venta'),
                  onPressed: _saleItems.isEmpty
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            if (isAnonymousSale || selectedCustomerId != null) {
                              final customerId = isAnonymousSale ? null : selectedCustomerId;
                              
                              salesService.registerSaleWithItems(
                                customerId,
                                _saleItems,
                                paymentType: paymentType,
                                paymentReceipt: paymentReceipt,
                              );
                              Navigator.pop(context);
                            }
                          }
                        },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
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
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
