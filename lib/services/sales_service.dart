// v1.7 - services/sales_service.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../models/customer.dart';
import 'product_service.dart';
import 'customer_service.dart';

class SalesService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProductService productService;
  final CustomerService customerService;

  SalesService({
    required this.productService,
    required this.customerService,
  }) {
    // No iniciar automáticamente, esperar a ser llamado después de la autenticación
  }

  // Inicializar el servicio después de la autenticación
  void initialize() {
    if (_sales.isEmpty) {
      _startListening();
    }
  }

  final List<Sale> _sales = [];
  bool _isLoading = false;
  DateTime? _lastCheckedDate;

  List<Sale> get sales => List.unmodifiable(_sales);
  bool get isLoading => _isLoading;

  // Escuchar cambios en tiempo real desde Firestore
  void _startListening() {
    _isLoading = true;
    notifyListeners();

    _firestore.collection('sales').orderBy('date', descending: true).snapshots().listen(
      (snapshot) {
        _sales.clear();
        
        for (var doc in snapshot.docs) {
          final sale = Sale.fromMap(doc.data(), doc.id);
          _sales.add(sale);
        }
        
        debugPrint('Ventas cargadas desde Firestore: ${_sales.length}');
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error listening to sales: $error');
        Fluttertoast.showToast(
          msg: "Error al cargar ventas: $error",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Método para refrescar manualmente
  Future<void> refreshSales() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final snapshot = await _firestore.collection('sales').orderBy('date', descending: true).get();
      _sales.clear();
      
      for (var doc in snapshot.docs) {
        final sale = Sale.fromMap(doc.data(), doc.id);
        _sales.add(sale);
      }
      
      debugPrint('Ventas refrescadas: ${_sales.length}');
    } catch (e) {
      debugPrint('Error refreshing sales: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  // Método principal para registrar ventas con múltiples productos
  Future<void> registerSaleWithItems(
    String? customerId,
    List<SaleItem> items, {
    String paymentType = 'Cash',
    String? paymentReceipt,
  }) async {
    if (items.isEmpty) {
      Fluttertoast.showToast(
        msg: "Debe agregar al menos un producto a la venta.",
        backgroundColor: Colors.redAccent,
      );
      return;
    }

    // Validar cliente
    if (customerId != null) {
      final customer = customerService.getById(customerId);
      if (customer.id == null) {
        Fluttertoast.showToast(
          msg: "Cliente no encontrado.",
          backgroundColor: Colors.redAccent,
        );
        return;
      }
    }

    // Validar stock de todos los productos
    for (var item in items) {
      final product = productService.getById(item.productId);
      if (product == null) {
        Fluttertoast.showToast(
          msg: "Producto no encontrado: ${item.productId}",
          backgroundColor: Colors.redAccent,
        );
        return;
      }

      if (product.stock <= 0) {
        Fluttertoast.showToast(
          msg: "❌ NO TIENES STOCK DE ${product.name.toUpperCase()}. SURTE TU INVENTARIO.",
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
        );
        return;
      }

      if (product.stock < item.quantity) {
        Fluttertoast.showToast(
          msg: "Stock insuficiente para vender ${item.quantity} unidades de ${product.name}.",
          backgroundColor: Colors.orangeAccent,
          textColor: Colors.white,
        );
        return;
      }
    }

    try {
      // Crear la venta
      final sale = Sale(
        date: DateTime.now(),
        customerId: customerId,
        items: items,
        paymentType: paymentType,
        paymentReceipt: paymentReceipt,
      );

      await _firestore.collection('sales').add(sale.toMap());

      // Disminuir stock de todos los productos
      for (var item in items) {
        await productService.decreaseStock(item.productId, item.quantity);
      }

      // Mensaje de confirmación
      final productNames = items.map((item) {
        final product = productService.getById(item.productId);
        return '${product?.name ?? "Producto"} x${item.quantity}';
      }).join(', ');

      Fluttertoast.showToast(
        msg: "✅ Venta registrada: $productNames → \$${sale.total.toStringAsFixed(0)}${customerId == null ? ' (Anónima)' : ''}",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      debugPrint('Error registering sale: $e');
      Fluttertoast.showToast(
        msg: "Error al registrar venta: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // Método de compatibilidad hacia atrás (mantiene la API antigua)
  Future<void> registerSale(
    String? customerId,
    String productId,
    int quantity, {
    String paymentType = 'Cash',
    String? paymentReceipt,
  }) async {
    final product = productService.getById(productId);
    if (product == null) {
      Fluttertoast.showToast(
        msg: "Producto no encontrado.",
        backgroundColor: Colors.redAccent,
      );
      return;
    }

    final item = SaleItem(
      productId: productId,
      quantity: quantity,
      unitPrice: product.price,
    );

    await registerSaleWithItems(
      customerId,
      [item],
      paymentType: paymentType,
      paymentReceipt: paymentReceipt,
    );
  }

  double get totalRevenue =>
      _sales.fold(0.0, (sum, sale) => sum + sale.total);

  int get totalUnitsSold =>
      _sales.fold(0, (sum, sale) => sum + sale.quantity);

  // Métodos para ventas del día actual
  List<Sale> get todaySales {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return _sales.where((sale) => 
      sale.date.isAfter(startOfDay) && sale.date.isBefore(endOfDay)
    ).toList();
  }

  double get todayRevenue => todaySales.fold(0.0, (sum, sale) => sum + sale.total);

  int get todayUnitsSold => todaySales.fold(0, (sum, sale) => sum + sale.quantity);

  int get todaySalesCount => todaySales.length;

  // Obtener ventas de un cliente específico
  List<Sale> getSalesByCustomer(String customerId) {
    return _sales.where((sale) => sale.customerId == customerId).toList();
  }

  // Obtener ventas pendientes de un cliente específico
  List<Sale> getPendingSalesByCustomer(String customerId) {
    return _sales.where((sale) => 
      sale.customerId == customerId && sale.isPending
    ).toList();
  }

  // Calcular deuda total de un cliente
  double getCustomerDebt(String customerId) {
    return getPendingSalesByCustomer(customerId)
        .fold(0.0, (sum, sale) => sum + sale.total);
  }

  // Obtener todas las ventas pendientes agrupadas por cliente
  Map<String, double> getPendingDebtsByCustomer() {
    final Map<String, double> debts = {};
    for (var sale in _sales) {
      if (sale.isPending && sale.customerId != null) {
        debts[sale.customerId!] = (debts[sale.customerId!] ?? 0) + sale.total;
      }
    }
    return debts;
  }

  // Verificar si ha cambiado el día y notificar a los listeners
  void checkDayChange() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    if (_lastCheckedDate == null || !_lastCheckedDate!.isAtSameMomentAs(todayDate)) {
      _lastCheckedDate = todayDate;
      debugPrint('Nuevo día detectado: ${todayDate.day}/${todayDate.month}/${todayDate.year}');
      notifyListeners(); // Notificar para actualizar las estadísticas del día
    }
  }

  Map<String, double> get revenueByProduct {
    final Map<String, double> data = {};
    for (var sale in _sales) {
      for (var item in sale.items) {
        final product = productService.getById(item.productId);
        if (product != null) {
          data[product.name] = (data[product.name] ?? 0) + item.subtotal;
        }
      }
    }
    return data;
  }

  Future<void> updatePaymentStatus(String saleId, String newPaymentType, {String? paymentReceipt}) async {
    try {
      await _firestore.collection('sales').doc(saleId).update({
        'paymentType': newPaymentType,
        'paymentReceipt': paymentReceipt,
        'updatedAt': Timestamp.now(),
      });

      // No actualizar manualmente la lista, el listener se encargará
      // El listener detectará el cambio y actualizará automáticamente
      
      Fluttertoast.showToast(
        msg: "💳 Estado de pago actualizado: $newPaymentType",
        backgroundColor: Colors.blue,
        textColor: Colors.white,
      );
    } catch (e) {
      debugPrint('Error updating payment status: $e');
      Fluttertoast.showToast(
        msg: "Error al actualizar estado de pago: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> updateSale(Sale updatedSale) async {
    if (updatedSale.id == null) {
      Fluttertoast.showToast(msg: "Error: ID de la venta no válido");
      return;
    }

    // Buscar la venta original
    final originalSaleIndex = _sales.indexWhere((s) => s.id == updatedSale.id);
    if (originalSaleIndex < 0) {
      Fluttertoast.showToast(msg: "Error: Venta no encontrada");
      return;
    }
    final originalSale = _sales[originalSaleIndex];

    // Validar stock de los nuevos productos
    for (var item in updatedSale.items) {
      final product = productService.getById(item.productId);
      if (product == null) {
        Fluttertoast.showToast(
          msg: "Producto no encontrado: ${item.productId}",
          backgroundColor: Colors.redAccent,
        );
        return;
      }

      // Calcular la cantidad actual en stock considerando la venta original
      int currentStock = product.stock;
      
      // Si el producto estaba en la venta original, sumar su cantidad
      final originalItem = originalSale.items.firstWhere(
        (i) => i.productId == item.productId,
        orElse: () => SaleItem(productId: '', quantity: 0, unitPrice: 0),
      );
      if (originalItem.productId.isNotEmpty) {
        currentStock += originalItem.quantity;
      }

      if (currentStock < item.quantity) {
        Fluttertoast.showToast(
          msg: "Stock insuficiente para vender ${item.quantity} unidades de ${product.name}.",
          backgroundColor: Colors.orangeAccent,
          textColor: Colors.white,
        );
        return;
      }
    }

    try {
      // Restaurar stock de productos que ya no están en la venta o que cambiaron
      for (var originalItem in originalSale.items) {
        final stillInSale = updatedSale.items.any((item) => item.productId == originalItem.productId);
        if (!stillInSale) {
          // El producto fue eliminado, restaurar todo su stock
          await productService.increaseStock(originalItem.productId, originalItem.quantity);
        } else {
          // El producto sigue en la venta, verificar si cambió la cantidad
          final updatedItem = updatedSale.items.firstWhere((item) => item.productId == originalItem.productId);
          if (updatedItem.quantity != originalItem.quantity) {
            final difference = updatedItem.quantity - originalItem.quantity;
            if (difference < 0) {
              // Se redujo la cantidad, restaurar la diferencia
              await productService.increaseStock(originalItem.productId, -difference);
            } else {
              // Se aumentó la cantidad, disminuir la diferencia
              await productService.decreaseStock(originalItem.productId, difference);
            }
          }
        }
      }

      // Disminuir stock de productos nuevos que no estaban en la venta original
      for (var updatedItem in updatedSale.items) {
        final wasInOriginal = originalSale.items.any((item) => item.productId == updatedItem.productId);
        if (!wasInOriginal) {
          // Es un producto nuevo, disminuir su stock
          await productService.decreaseStock(updatedItem.productId, updatedItem.quantity);
        }
      }

      // Actualizar la venta en Firestore
      await _firestore.collection('sales').doc(updatedSale.id).update(updatedSale.toMap());
      
      // No actualizar manualmente la lista, el listener se encargará
      // El listener detectará el cambio y actualizará automáticamente
      
      Fluttertoast.showToast(
        msg: "✅ Venta actualizada correctamente",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      debugPrint('Error updating sale: $e');
      Fluttertoast.showToast(
        msg: "Error al actualizar venta: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // Método para borrar todas las ventas
  Future<void> deleteAllSales() async {
    try {
      // Obtener todas las ventas
      final snapshot = await _firestore.collection('sales').get();
      
      // Borrar cada venta
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      
      debugPrint('Todas las ventas han sido borradas');
      Fluttertoast.showToast(
        msg: "✅ Todas las ventas han sido borradas",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      debugPrint('Error deleting all sales: $e');
      Fluttertoast.showToast(
        msg: "Error al borrar todas las ventas: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // Método para borrar ventas seleccionadas
  Future<void> deleteSelectedSales(List<String> saleIds) async {
    try {
      // Borrar cada venta seleccionada
      for (var saleId in saleIds) {
        await _firestore.collection('sales').doc(saleId).delete();
      }
      
      debugPrint('${saleIds.length} ventas han sido borradas');
      Fluttertoast.showToast(
        msg: "✅ ${saleIds.length} ventas han sido borradas",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      debugPrint('Error deleting selected sales: $e');
      Fluttertoast.showToast(
        msg: "Error al borrar las ventas seleccionadas: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> deleteSale(String saleId) async {
    try {
      final saleIndex = _sales.indexWhere((s) => s.id == saleId);
      if (saleIndex >= 0) {
        final sale = _sales[saleIndex];
        
        // Restaurar stock de todos los productos en la venta
        for (var item in sale.items) {
          final product = productService.getById(item.productId);
          if (product != null) {
            await productService.increaseStock(item.productId, item.quantity);
          }
        }
        
        await _firestore.collection('sales').doc(saleId).delete();
        
        // No remover manualmente de la lista, el listener se encargará
        // _sales.removeAt(saleIndex); // REMOVIDO - causa inconsistencias
        // notifyListeners(); // REMOVIDO - el listener lo hará automáticamente
        
        Fluttertoast.showToast(
          msg: "🗑️ Venta eliminada y stock restaurado",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Error deleting sale: $e');
      Fluttertoast.showToast(
        msg: "Error al eliminar venta: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> clearSales() async {
    try {
      // Eliminar todas las ventas de Firestore
      final batch = _firestore.batch();
      final snapshot = await _firestore.collection('sales').get();
      
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      // No limpiar manualmente la lista, el listener se encargará
      // _sales.clear(); // REMOVIDO - el listener detectará los cambios
      // notifyListeners(); // REMOVIDO - el listener lo hará automáticamente
      
      Fluttertoast.showToast(
        msg: "🗑️ Todas las ventas han sido eliminadas",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } catch (e) {
      debugPrint('Error clearing sales: $e');
      Fluttertoast.showToast(
        msg: "Error al eliminar ventas: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }
}
