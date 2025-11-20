// v1.6 - services/auth_service.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'product_service.dart';
import 'customer_service.dart';
import 'sales_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserModel? _currentUser;
  bool _isLoading = false;

  // Referencias a otros servicios para inicializarlos después del login
  ProductService? _productService;
  CustomerService? _customerService;
  SalesService? _salesService;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isDeveloper => _currentUser?.isDeveloper ?? false;

  // Método para establecer las referencias a los servicios
  void setServices({
    required ProductService productService,
    required CustomerService customerService,
    required SalesService salesService,
  }) {
    _productService = productService;
    _customerService = customerService;
    _salesService = salesService;
  }

  AuthService() {
    // Escuchar cambios en el estado de autenticación
    _auth.authStateChanges().listen(_onAuthStateChanged);
    
    // Verificar si hay un usuario autenticado al inicializar
    _checkCurrentUser();
  }

  // Verificar usuario actual al inicializar
  Future<void> _checkCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null && _currentUser == null) {
      await _loadUserFromFirestore(user.uid);
    }
  }

  // Método que se ejecuta cuando cambia el estado de autenticación
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser != null) {
      // Usuario autenticado, obtener datos del usuario desde Firestore
      await _loadUserFromFirestore(firebaseUser.uid);
      
      // Inicializar los servicios de datos si el usuario ya estaba autenticado
      if (_currentUser != null) {
        _initializeDataServices();
      }
    } else {
      // Usuario no autenticado
      _currentUser = null;
      notifyListeners();
    }
  }

  // Cargar datos del usuario desde Firestore
  Future<void> _loadUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _currentUser = UserModel(
          id: uid, // Usar el UID directamente como String
          username: data['username'] ?? '',
          email: data['email'] ?? '',
          password: '', // No guardamos la contraseña en el modelo local
          fullName: data['fullName'] ?? '',
          role: data['role'] ?? 'worker',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
          isActive: data['isActive'] ?? true,
          subscriptionActive: data['subscriptionActive'] ?? false,
          subscriptionExpiryDate: (data['subscriptionExpiryDate'] as Timestamp?)?.toDate(),
          trialDays: data['trialDays'] ?? 0,
          trialExpiryDate: (data['trialExpiryDate'] as Timestamp?)?.toDate(),
        );
        debugPrint('Usuario cargado desde Firestore: ${_currentUser?.fullName}');
        notifyListeners();
      } else {
        debugPrint('No se encontró documento del usuario en Firestore para UID: $uid');
      }
    } catch (e) {
      debugPrint('Error loading user from Firestore: $e');
    }
  }

  // Login con Firebase Auth
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Verificar y crear documento del admin si es necesario
        await ensureAdminDocumentExists();
        
        // Esperar a que se carguen los datos del usuario desde Firestore
        await _loadUserFromFirestore(credential.user!.uid);
        
        // Inicializar los servicios de datos después del login exitoso
        _initializeDataServices();
        
        _isLoading = false;
        notifyListeners();

        Fluttertoast.showToast(
          msg: "✅ Bienvenido, ${_currentUser?.fullName ?? 'Usuario'}",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();

      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No existe una cuenta con este email';
          break;
        case 'wrong-password':
          errorMessage = 'Contraseña incorrecta';
          break;
        case 'invalid-email':
          errorMessage = 'Email inválido';
          break;
        case 'user-disabled':
          errorMessage = 'Esta cuenta ha sido deshabilitada';
          break;
        case 'too-many-requests':
          errorMessage = 'Demasiados intentos fallidos. Intenta más tarde';
          break;
        default:
          errorMessage = 'Error de autenticación: ${e.message}';
      }

      Fluttertoast.showToast(
        msg: "❌ $errorMessage",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );

      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      Fluttertoast.showToast(
        msg: "❌ Error inesperado: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );

      return false;
    }
  }

  // Registro con Firebase Auth
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Crear usuario en Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Guardar datos adicionales del usuario en Firestore
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'username': username,
          'email': email,
          'fullName': fullName,
          'role': role,
          'createdAt': Timestamp.now(),
          'lastLogin': null,
          'isActive': true,
        });

        // Cargar los datos del usuario recién creado
        await _loadUserFromFirestore(credential.user!.uid);

        _isLoading = false;
        notifyListeners();

        Fluttertoast.showToast(
          msg: "✅ Usuario registrado correctamente",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();

      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'La contraseña es muy débil';
          break;
        case 'email-already-in-use':
          errorMessage = 'Ya existe una cuenta con este email';
          break;
        case 'invalid-email':
          errorMessage = 'Email inválido';
          break;
        default:
          errorMessage = 'Error de registro: ${e.message}';
      }

      Fluttertoast.showToast(
        msg: "❌ $errorMessage",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );

      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      Fluttertoast.showToast(
        msg: "❌ Error inesperado: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );

      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      notifyListeners();

      Fluttertoast.showToast(
        msg: "👋 Sesión cerrada",
        backgroundColor: Colors.blue,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "❌ Error al cerrar sesión",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // Cambiar contraseña
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (_currentUser == null) return false;

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Reautenticar usuario
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        
        await user.reauthenticateWithCredential(credential);
        
        // Cambiar contraseña
        await user.updatePassword(newPassword);

        Fluttertoast.showToast(
          msg: "✅ Contraseña actualizada",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        return true;
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "❌ Error al cambiar contraseña: ${e.toString()}",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
    return false;
  }

  // Actualizar perfil
  Future<bool> updateProfile({
    String? username,
    String? email,
    String? fullName,
  }) async {
    if (_currentUser == null) return false;

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Actualizar email en Firebase Auth si es necesario
        if (email != null && email != user.email) {
          await user.verifyBeforeUpdateEmail(email);
        }

        // Actualizar datos en Firestore
        await _firestore.collection('users').doc(user.uid).update({
          if (username != null) 'username': username,
          if (email != null) 'email': email,
          if (fullName != null) 'fullName': fullName,
        });

        // Recargar datos del usuario
        await _loadUserFromFirestore(user.uid);

        Fluttertoast.showToast(
          msg: "✅ Perfil actualizado",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        return true;
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "❌ Error al actualizar perfil: ${e.toString()}",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
    return false;
  }

  // Obtener todos los usuarios (solo para admin)
  Future<List<UserModel>> getAllUsers() async {
    if (!isAdmin) return [];

    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel(
          id: doc.id, // Usar el ID del documento directamente
          username: data['username'] ?? '',
          email: data['email'] ?? '',
          password: '',
          fullName: data['fullName'] ?? '',
          role: data['role'] ?? 'worker',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
          isActive: data['isActive'] ?? true,
          subscriptionActive: data['subscriptionActive'] ?? false,
          subscriptionExpiryDate: (data['subscriptionExpiryDate'] as Timestamp?)?.toDate(),
          trialDays: data['trialDays'] ?? 0,
          trialExpiryDate: (data['trialExpiryDate'] as Timestamp?)?.toDate(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return [];
    }
  }

  // Activar/Desactivar usuario (solo para admin)
  Future<bool> toggleUserStatus(String userId) async {
    if (!isAdmin) return false;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final currentStatus = doc.data()?['isActive'] ?? true;
        await _firestore.collection('users').doc(userId).update({
          'isActive': !currentStatus,
        });

        Fluttertoast.showToast(
          msg: "✅ Estado de usuario actualizado",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        return true;
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "❌ Error al actualizar usuario: ${e.toString()}",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
    return false;
  }

  // Método para refrescar datos del usuario actual
  Future<void> refreshCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _loadUserFromFirestore(user.uid);
    }
  }

  // Método para inicializar usuario admin por defecto
  Future<void> initializeDefaultAdmin() async {
    try {
      // Verificar si ya existe un usuario admin
      final adminSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (adminSnapshot.docs.isEmpty) {
        // Crear usuario admin por defecto
        final adminEmail = 'admin@cervezapp.com';
        final adminPassword = 'CervezApp2024!';

        try {
          final credential = await _auth.createUserWithEmailAndPassword(
            email: adminEmail,
            password: adminPassword,
          );

          if (credential.user != null) {
            await _firestore.collection('users').doc(credential.user!.uid).set({
              'username': 'admin',
              'email': adminEmail,
              'fullName': 'Administrador',
              'role': 'admin',
              'createdAt': Timestamp.now(),
              'lastLogin': null,
              'isActive': true,
            });

            debugPrint('Usuario admin creado por defecto');
          }
        } catch (e) {
          debugPrint('Error creando usuario admin: $e');
        }
      }
    } catch (e) {
      debugPrint('Error inicializando admin por defecto: $e');
    }
  }

  // Función para verificar y crear documento del admin si no existe
  Future<void> ensureAdminDocumentExists() async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email == 'admin@cervezapp.com') {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        
        if (!doc.exists) {
          // Crear el documento del admin si no existe
          await _firestore.collection('users').doc(user.uid).set({
            'username': 'admin',
            'email': 'admin@cervezapp.com',
            'fullName': 'Administrador',
            'role': 'admin',
            'createdAt': Timestamp.now(),
            'lastLogin': null,
            'isActive': true,
          });
          
          debugPrint('Documento del admin creado en Firestore');
          
          // Recargar los datos del usuario
          await _loadUserFromFirestore(user.uid);
        }
      }
    } catch (e) {
      debugPrint('Error verificando documento del admin: $e');
    }
  }

  // Inicializar los servicios de datos después del login exitoso
  void _initializeDataServices() {
    try {
      _productService?.initialize();
      _customerService?.initialize();
      _salesService?.initialize();
      debugPrint('Servicios de datos inicializados después del login');
    } catch (e) {
      debugPrint('Error inicializando servicios de datos: $e');
    }
  }
}
