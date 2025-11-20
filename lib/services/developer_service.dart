// services/developer_service.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import 'auth_service.dart';

class DeveloperService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;
  
  List<UserModel> _users = [];
  bool _isLoading = false;

  DeveloperService(this._authService);

  List<UserModel> get users => List.unmodifiable(_users);
  bool get isLoading => _isLoading;

  // Verificar si el usuario actual es desarrollador
  bool get _isAuthorized => _authService.isDeveloper;

  // Cargar todos los usuarios (solo para desarrolladores)
  Future<void> loadAllUsers() async {
    if (!_isAuthorized) {
      debugPrint('Acceso denegado: el usuario no es desarrollador');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('users').get();
      _users = snapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel.fromMap(data, doc.id);
      }).toList();
      
      debugPrint('Usuarios cargados: ${_users.length}');
    } catch (e) {
      debugPrint('Error cargando usuarios: $e');
      Fluttertoast.showToast(
        msg: "❌ Error al cargar usuarios: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Activar/Desactivar suscripción
  Future<bool> toggleSubscription(String userId) async {
    if (!_isAuthorized) return false;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;

      final currentStatus = doc.data()?['subscriptionActive'] ?? false;
      final now = DateTime.now();
      
      await _firestore.collection('users').doc(userId).update({
        'subscriptionActive': !currentStatus,
        'updatedAt': Timestamp.now(),
        if (!currentStatus && doc.data()?['subscriptionExpiryDate'] == null)
          'subscriptionExpiryDate': Timestamp.fromDate(
            now.add(const Duration(days: 30)) // 30 días por defecto
          ),
      });

      await loadAllUsers();

      Fluttertoast.showToast(
        msg: currentStatus 
          ? "✅ Suscripción desactivada" 
          : "✅ Suscripción activada por 30 días",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      return true;
    } catch (e) {
      debugPrint('Error al cambiar suscripción: $e');
      Fluttertoast.showToast(
        msg: "❌ Error al cambiar suscripción: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }
  }

  // Modificar o extender días de prueba
  Future<bool> updateTrialDays(String userId, int days) async {
    if (!_isAuthorized) return false;
    if (days < 0) {
      Fluttertoast.showToast(
        msg: "❌ Los días deben ser positivos",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }

    try {
      final now = DateTime.now();
      final expiryDate = now.add(Duration(days: days));

      await _firestore.collection('users').doc(userId).update({
        'trialDays': days,
        'trialExpiryDate': days > 0 
          ? Timestamp.fromDate(expiryDate)
          : null,
        'updatedAt': Timestamp.now(),
      });

      await loadAllUsers();

      Fluttertoast.showToast(
        msg: days > 0
          ? "✅ Período de prueba extendido a $days días"
          : "✅ Período de prueba eliminado",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      return true;
    } catch (e) {
      debugPrint('Error al actualizar días de prueba: $e');
      Fluttertoast.showToast(
        msg: "❌ Error al actualizar días de prueba: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }
  }

  // Extender fecha de expiración de suscripción
  Future<bool> extendSubscription(String userId, int additionalDays) async {
    if (!_isAuthorized) return false;
    if (additionalDays <= 0) {
      Fluttertoast.showToast(
        msg: "❌ Los días deben ser mayores a 0",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;

      final currentExpiry = (doc.data()?['subscriptionExpiryDate'] as Timestamp?)?.toDate();
      final newExpiry = (currentExpiry ?? DateTime.now()).add(Duration(days: additionalDays));

      await _firestore.collection('users').doc(userId).update({
        'subscriptionActive': true,
        'subscriptionExpiryDate': Timestamp.fromDate(newExpiry),
        'updatedAt': Timestamp.now(),
      });

      await loadAllUsers();

      Fluttertoast.showToast(
        msg: "✅ Suscripción extendida $additionalDays días más",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      return true;
    } catch (e) {
      debugPrint('Error al extender suscripción: $e');
      Fluttertoast.showToast(
        msg: "❌ Error al extender suscripción: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }
  }

  // Eliminar usuario
  Future<bool> deleteUser(String userId) async {
    if (!_isAuthorized) return false;

    try {
      // No permitir eliminar al propio desarrollador
      if (userId == _authService.currentUser?.id) {
        Fluttertoast.showToast(
          msg: "❌ No puedes eliminar tu propia cuenta",
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
        return false;
      }

      await _firestore.collection('users').doc(userId).delete();

      await loadAllUsers();

      Fluttertoast.showToast(
        msg: "✅ Usuario eliminado",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      return true;
    } catch (e) {
      debugPrint('Error al eliminar usuario: $e');
      Fluttertoast.showToast(
        msg: "❌ Error al eliminar usuario: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }
  }

  // Cambiar rol de usuario (solo developer puede hacer esto)
  Future<bool> changeUserRole(String userId, String newRole) async {
    if (!_isAuthorized) return false;

    // Validar que el rol sea válido
    if (!['worker', 'admin', 'developer'].contains(newRole)) {
      Fluttertoast.showToast(
        msg: "❌ Rol inválido",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }

    // No permitir cambiar tu propio rol
    if (userId == _authService.currentUser?.id) {
      Fluttertoast.showToast(
        msg: "❌ No puedes cambiar tu propio rol",
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return false;
    }

    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': Timestamp.now(),
      });

      await loadAllUsers();

      Fluttertoast.showToast(
        msg: "✅ Rol actualizado a: ${_getRoleName(newRole)}",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      return true;
    } catch (e) {
      debugPrint('Error al cambiar rol: $e');
      Fluttertoast.showToast(
        msg: "❌ Error al cambiar rol: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }
  }

  // Obtener nombre del rol en español
  String _getRoleName(String role) {
    switch (role) {
      case 'worker':
        return 'Trabajador';
      case 'admin':
        return 'Administrador';
      case 'developer':
        return 'Desarrollador';
      default:
        return role;
    }
  }

  // Resetear contraseña de un usuario
  // Nota: Firebase no permite ver contraseñas, solo resetearlas
  // Esta función enviará un email de reset
  Future<bool> resetUserPassword(String userEmail) async {
    if (!_isAuthorized) return false;

    try {
      final auth = FirebaseAuth.instance;
      
      // Enviar email de reset de contraseña
      await auth.sendPasswordResetEmail(email: userEmail);
      
      Fluttertoast.showToast(
        msg: "✅ Email de reset enviado a $userEmail",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      
      return true;
    } catch (e) {
      debugPrint('Error al resetear contraseña: $e');
      Fluttertoast.showToast(
        msg: "❌ Error: ${e.toString()}",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }
  }

  // Obtener estadísticas
  Map<String, int> getStatistics() {
    final total = _users.length;
    final active = _users.where((u) => u.hasActiveSubscription).length;
    final inTrial = _users.where((u) => u.isInTrial && !u.hasActiveSubscription).length;
    final expired = _users.where((u) => u.isExpired).length;

    return {
      'total': total,
      'active': active,
      'inTrial': inTrial,
      'expired': expired,
    };
  }
}

