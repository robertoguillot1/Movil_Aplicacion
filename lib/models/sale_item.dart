// v1.7 - models/sale_item.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SaleItem {
  final String productId;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  SaleItem({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  }) : subtotal = unitPrice * quantity;

  // Constructor con subtotal explícito (útil para deserialización)
  SaleItem.withSubtotal({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  // Método para convertir a Map (útil para Firestore)
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'subtotal': subtotal,
    };
  }

  // Método para crear desde Map
  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem.withSubtotal(
      productId: map['productId'] ?? '',
      quantity: map['quantity'] ?? 0,
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
    );
  }

  // Método para crear una copia con cambios
  SaleItem copyWith({
    String? productId,
    int? quantity,
    double? unitPrice,
  }) {
    return SaleItem(
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  @override
  String toString() {
    return 'SaleItem(productId: $productId, quantity: $quantity, unitPrice: $unitPrice, subtotal: $subtotal)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SaleItem &&
        other.productId == productId &&
        other.quantity == quantity &&
        other.unitPrice == unitPrice;
  }

  @override
  int get hashCode => Object.hash(productId, quantity, unitPrice);
}

