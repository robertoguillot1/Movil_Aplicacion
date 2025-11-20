// v1.6 - services/customer_service.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';

class CustomerService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Customer> _customers = [];
  bool _isLoading = false;

  List<Customer> get customers => List.unmodifiable(_customers);
  bool get isLoading => _isLoading;

  CustomerService() {
    // No iniciar automáticamente, esperar a ser llamado después de la autenticación
  }

  // Inicializar el servicio después de la autenticación
  void initialize() {
    if (_customers.isEmpty) {
      _startListening();
    }
  }

  // Escuchar cambios en tiempo real desde Firestore
  void _startListening() {
    _isLoading = true;
    notifyListeners();

    _firestore.collection('customers').snapshots().listen(
      (snapshot) {
        _customers.clear();
        
        for (var doc in snapshot.docs) {
          final customer = Customer.fromMap(doc.data(), doc.id);
          _customers.add(customer);
        }
        
        debugPrint('Clientes cargados desde Firestore: ${_customers.length}');
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error listening to customers: $error');
        Fluttertoast.showToast(
          msg: "Error al cargar clientes: $error",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Método para refrescar manualmente
  Future<void> refreshCustomers() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final snapshot = await _firestore.collection('customers').get();
      _customers.clear();
      
      for (var doc in snapshot.docs) {
        final customer = Customer.fromMap(doc.data(), doc.id);
        _customers.add(customer);
      }
      
      debugPrint('Clientes refrescados: ${_customers.length}');
    } catch (e) {
      debugPrint('Error refreshing customers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Customer getById(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return Customer.empty();
    }
  }

  Future<void> addCustomer(String name, {String? email, String? phone}) async {
    if (name.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: "El nombre del cliente no puede estar vacío",
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
      );
      return;
    }

    // Validar email si se proporciona
    if (email != null && email.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email)) {
        Fluttertoast.showToast(
          msg: "El formato del email no es válido",
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
        );
        return;
      }
    }

    // Validar teléfono si se proporciona
    if (phone != null && phone.isNotEmpty) {
      final phoneRegex = RegExp(r'^[0-9]{10}$');
      if (!phoneRegex.hasMatch(phone)) {
        Fluttertoast.showToast(
          msg: "El teléfono debe tener 10 dígitos",
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
        );
        return;
      }
    }

    try {
      final customer = Customer(
        name: name.trim(),
        email: email?.trim(),
        phone: phone?.trim(),
      );

      final docRef = await _firestore.collection('customers').add(customer.toMap());
      final newCustomer = customer.copyWith(id: docRef.id);
      
      _customers.add(newCustomer);
      notifyListeners();

      Fluttertoast.showToast(
        msg: "✅ Cliente agregado: $name",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      debugPrint('Error adding customer: $e');
      Fluttertoast.showToast(
        msg: "Error al agregar cliente: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> updateCustomer(Customer updated) async {
    if (updated.id == null) {
      Fluttertoast.showToast(msg: "Error: ID del cliente no válido");
      return;
    }

    try {
      await _firestore.collection('customers').doc(updated.id).update(updated.toMap());
      
      final index = _customers.indexWhere((c) => c.id == updated.id);
      if (index >= 0) {
        _customers[index] = updated;
        notifyListeners();

        Fluttertoast.showToast(
          msg: "📝 Cliente actualizado: ${updated.name}",
          backgroundColor: Colors.orangeAccent,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Error updating customer: $e');
      Fluttertoast.showToast(
        msg: "Error al actualizar cliente: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> deleteCustomer(String id) async {
    final customer = getById(id);
    if (customer.id == null) {
      Fluttertoast.showToast(msg: "Cliente no encontrado");
      return;
    }

    try {
      await _firestore.collection('customers').doc(id).delete();
      _customers.removeWhere((c) => c.id == id);
      notifyListeners();

      Fluttertoast.showToast(
        msg: "🗑️ Cliente eliminado: ${customer.name}",
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
      );
    } catch (e) {
      debugPrint('Error deleting customer: $e');
      Fluttertoast.showToast(
        msg: "Error al eliminar cliente: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // Método para inicializar clientes por defecto
  Future<void> initializeDefaultCustomers() async {
    try {
      // Verificar si ya existen clientes
      final snapshot = await _firestore.collection('customers').limit(1).get();
      
      if (snapshot.docs.isEmpty) {
        // Crear clientes por defecto
        final defaultCustomers = [
          {'name': 'Juan Pérez', 'email': 'juanperez@mail.com', 'phone': '3011234567'},
          {'name': 'María Gómez', 'email': 'mariagomez@mail.com', 'phone': '3027654321'},
          {'name': 'Andrés López', 'email': 'andreslopez@mail.com', 'phone': '3009988776'},
        ];

        for (var customerData in defaultCustomers) {
          await _firestore.collection('customers').add({
            ...customerData,
            'createdAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
          });
        }

        debugPrint('Clientes por defecto creados');
        // Los clientes se recargarán automáticamente por el listener
      }
    } catch (e) {
      debugPrint('Error inicializando clientes por defecto: $e');
    }
  }
}