// v1.6 - models/user.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String? id; // Cambiado a String? para Firestore
  final String username;
  final String email;
  final String password; // En producción debería estar hasheada
  final String fullName;
  final String role; // 'admin', 'worker' o 'developer'
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool isActive;
  final DateTime? updatedAt; // Agregado para Firestore
  final bool subscriptionActive; // Estado de suscripción
  final DateTime? subscriptionExpiryDate; // Fecha de expiración de suscripción
  final int trialDays; // Días de prueba
  final DateTime? trialExpiryDate; // Fecha de expiración de prueba

  UserModel({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.fullName,
    required this.role,
    required this.createdAt,
    this.lastLogin,
    this.isActive = true,
    this.updatedAt,
    this.subscriptionActive = false,
    this.subscriptionExpiryDate,
    this.trialDays = 0,
    this.trialExpiryDate,
  });

  // Getters para verificar roles
  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isDeveloper => role.toLowerCase() == 'developer';
  
  // Getters para estado de suscripción
  bool get hasActiveSubscription => subscriptionActive && 
    (subscriptionExpiryDate == null || subscriptionExpiryDate!.isAfter(DateTime.now()));
  bool get isInTrial => trialDays > 0 && 
    (trialExpiryDate == null || trialExpiryDate!.isAfter(DateTime.now()));
  bool get isExpired => !hasActiveSubscription && !isInTrial;

  // Método para crear una copia con cambios
  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? password,
    String? fullName,
    String? role,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isActive,
    DateTime? updatedAt,
    bool? subscriptionActive,
    DateTime? subscriptionExpiryDate,
    int? trialDays,
    DateTime? trialExpiryDate,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
      subscriptionActive: subscriptionActive ?? this.subscriptionActive,
      subscriptionExpiryDate: subscriptionExpiryDate ?? this.subscriptionExpiryDate,
      trialDays: trialDays ?? this.trialDays,
      trialExpiryDate: trialExpiryDate ?? this.trialExpiryDate,
    );
  }

  // Método para convertir a Map (útil para Firestore)
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'fullName': fullName,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'isActive': isActive,
      'updatedAt': Timestamp.fromDate(updatedAt ?? DateTime.now()),
      'subscriptionActive': subscriptionActive,
      'subscriptionExpiryDate': subscriptionExpiryDate != null 
        ? Timestamp.fromDate(subscriptionExpiryDate!) 
        : null,
      'trialDays': trialDays,
      'trialExpiryDate': trialExpiryDate != null 
        ? Timestamp.fromDate(trialExpiryDate!) 
        : null,
    };
  }

  // Método para crear desde Map (desde Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      id: documentId,
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      fullName: map['fullName'] ?? '',
      role: map['role'] ?? 'worker',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (map['lastLogin'] as Timestamp?)?.toDate(),
      isActive: map['isActive'] ?? true,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      subscriptionActive: map['subscriptionActive'] ?? false,
      subscriptionExpiryDate: (map['subscriptionExpiryDate'] as Timestamp?)?.toDate(),
      trialDays: map['trialDays'] ?? 0,
      trialExpiryDate: (map['trialExpiryDate'] as Timestamp?)?.toDate(),
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, email: $email, fullName: $fullName, role: $role, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

