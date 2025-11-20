// v1.6 - services/product_service.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Product> _products = [];
  bool _isLoading = false;

  // Configurable: cuando el stock <= threshold, muestra alerta
  final int lowStockThreshold = 5;

  List<Product> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;

  ProductService() {
    // No iniciar automáticamente, esperar a ser llamado después de la autenticación
  }

  // Inicializar el servicio después de la autenticación
  void initialize() {
    if (_products.isEmpty) {
      _startListening();
    }
  }

  // Escuchar cambios en tiempo real desde Firestore
  void _startListening() {
    _isLoading = true;
    notifyListeners();

    _firestore.collection('products').snapshots().listen(
      (snapshot) {
        _products.clear();
        
        for (var doc in snapshot.docs) {
          final product = Product.fromMap(doc.data(), doc.id);
          _products.add(product);
        }
        
        debugPrint('Productos cargados desde Firestore: ${_products.length}');
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error listening to products: $error');
        Fluttertoast.showToast(
          msg: "Error al cargar productos: $error",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Método para refrescar manualmente
  Future<void> refreshProducts() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final snapshot = await _firestore.collection('products').get();
      _products.clear();
      
      for (var doc in snapshot.docs) {
        final product = Product.fromMap(doc.data(), doc.id);
        _products.add(product);
      }
      
      debugPrint('Productos refrescados: ${_products.length}');
    } catch (e) {
      debugPrint('Error refreshing products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Product? getById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Product> addProduct(String name, double price, int stock, {String? category}) async {
    if (name.trim().isEmpty) {
      Fluttertoast.showToast(msg: "El nombre del producto no puede estar vacío");
      throw Exception("Nombre vacío");
    }
    if (price <= 0 || stock < 0) {
      Fluttertoast.showToast(msg: "Precio o stock inválido");
      throw Exception("Valores inválidos");
    }

    try {
      final product = Product(
        name: name.trim(),
        price: price,
        stock: stock,
        category: category,
      );

      final docRef = await _firestore.collection('products').add(product.toMap());
      final newProduct = product.copyWith(id: docRef.id);
      
      _products.add(newProduct);
      notifyListeners();

      Fluttertoast.showToast(msg: "Producto agregado: ${newProduct.name}");
      return newProduct;
    } catch (e) {
      debugPrint('Error adding product: $e');
      Fluttertoast.showToast(
        msg: "Error al agregar producto: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      rethrow;
    }
  }

  Future<void> updateProduct(Product updated) async {
    if (updated.id == null) {
      Fluttertoast.showToast(msg: "Error: ID del producto no válido");
      return;
    }

    try {
      await _firestore.collection('products').doc(updated.id).update(updated.toMap());
      
      final index = _products.indexWhere((p) => p.id == updated.id);
      if (index >= 0) {
        _products[index] = updated;
        notifyListeners();
        Fluttertoast.showToast(msg: "Producto actualizado: ${updated.name}");
      }
    } catch (e) {
      debugPrint('Error updating product: $e');
      Fluttertoast.showToast(
        msg: "Error al actualizar producto: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> deleteProduct(String id) async {
    final product = getById(id);
    if (product == null) {
      Fluttertoast.showToast(msg: "Producto no encontrado");
      return;
    }

    try {
      await _firestore.collection('products').doc(id).delete();
      _products.removeWhere((p) => p.id == id);
      notifyListeners();

      Fluttertoast.showToast(
        msg: "🗑️ Producto eliminado: ${product.name}",
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
      );
    } catch (e) {
      debugPrint('Error deleting product: $e');
      Fluttertoast.showToast(
        msg: "Error al eliminar producto: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> decreaseStock(String productId, int quantity) async {
    final product = getById(productId);
    if (product == null || product.stock < quantity) {
      Fluttertoast.showToast(msg: "Stock insuficiente para venta");
      throw Exception("Stock insuficiente");
    }

    try {
      final newStock = product.stock - quantity;
      final updatedProduct = product.copyWith(stock: newStock);
      
      await _firestore.collection('products').doc(productId).update({
        'stock': newStock,
        'updatedAt': Timestamp.now(),
      });

      final index = _products.indexWhere((p) => p.id == productId);
      if (index >= 0) {
        _products[index] = updatedProduct;
      }

      // Notificaciones automáticas
      if (newStock == 0) {
        Fluttertoast.showToast(
          msg: "🚨 ¡AGOTADO! ${product.name} - Stock: 0",
          backgroundColor: Colors.red,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
      } else if (newStock <= lowStockThreshold) {
        Fluttertoast.showToast(
          msg: "⚠️ Quedan $newStock unidades de ${product.name}",
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error decreasing stock: $e');
      Fluttertoast.showToast(
        msg: "Error al actualizar stock: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      rethrow;
    }
  }

  Future<void> increaseStock(String productId, int quantity) async {
    final product = getById(productId);
    if (product == null) {
      Fluttertoast.showToast(msg: "Producto no encontrado");
      return;
    }

    try {
      final newStock = product.stock + quantity;
      final updatedProduct = product.copyWith(stock: newStock);
      
      await _firestore.collection('products').doc(productId).update({
        'stock': newStock,
        'updatedAt': Timestamp.now(),
      });

      final index = _products.indexWhere((p) => p.id == productId);
      if (index >= 0) {
        _products[index] = updatedProduct;
      }

      notifyListeners();
      Fluttertoast.showToast(msg: "Stock actualizado: ${product.name} → $newStock");
    } catch (e) {
      debugPrint('Error increasing stock: $e');
      Fluttertoast.showToast(
        msg: "Error al actualizar stock: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  List<Product> getLowStockProducts() {
    return _products.where((p) => p.stock <= lowStockThreshold).toList();
  }

  double get totalInventoryValue {
    return _products.fold(0.0, (sum, p) => sum + (p.price * p.stock));
  }

  double get averagePrice {
    if (_products.isEmpty) return 0.0;
    return _products.fold(0.0, (sum, p) => sum + p.price) / _products.length;
  }

  // Método para inicializar productos por defecto
  Future<void> initializeDefaultProducts() async {
    try {
      // Verificar si ya existen productos
      final snapshot = await _firestore.collection('products').limit(1).get();
      
      if (snapshot.docs.isEmpty) {
        // Crear productos por defecto
        final defaultProducts = [
          {'name': 'Cerveza Águila', 'price': 3500.0, 'stock': 12, 'category': 'beer'},
          {'name': 'Poker', 'price': 3300.0, 'stock': 6, 'category': 'beer'},
          {'name': 'Club Colombia', 'price': 4200.0, 'stock': 3, 'category': 'beer'},
        ];

        for (var productData in defaultProducts) {
          await _firestore.collection('products').add({
            ...productData,
            'createdAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
          });
        }

        debugPrint('Productos por defecto creados');
        // Los productos se recargarán automáticamente por el listener
      }
    } catch (e) {
      debugPrint('Error inicializando productos por defecto: $e');
    }
  }
}