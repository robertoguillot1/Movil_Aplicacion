// v1.7 - models/sale.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sale_item.dart';

class Sale {
  final String? id;
  final DateTime date;
  final String? customerId;
  final List<SaleItem> items; // Lista de productos en la venta
  String paymentType; // 'Cash', 'Nequi', 'Pending'
  String? paymentReceipt; // Path to receipt image for Nequi payments
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Getters calculados para compatibilidad hacia atrás
  String? get productId => items.isNotEmpty ? items.first.productId : null;
  int get quantity => items.fold(0, (sum, item) => sum + item.quantity);
  double get total => items.fold(0.0, (sum, item) => sum + item.subtotal);
  
  bool get isPending => paymentType.toLowerCase() == 'pending';
  bool get hasReceipt => paymentReceipt != null && paymentReceipt!.isNotEmpty;

  Sale({
    this.id,
    required this.date,
    this.customerId,
    required this.items,
    this.paymentType = 'Cash',
    this.paymentReceipt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Método para convertir a Map (útil para Firestore)
  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'customerId': customerId,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'paymentType': paymentType,
      'paymentReceipt': paymentReceipt,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Método para crear desde Map (con compatibilidad hacia atrás)
  factory Sale.fromMap(Map<String, dynamic> map, String id) {
    List<SaleItem> items = [];
    
    // Si existe 'items', usar el nuevo formato
    if (map['items'] != null && map['items'] is List) {
      items = (map['items'] as List)
          .map((item) => SaleItem.fromMap(item as Map<String, dynamic>))
          .toList();
    }
    // Si no, migrar del formato antiguo (compatibilidad hacia atrás)
    else if (map['productId'] != null) {
      final productId = map['productId'] as String;
      final quantity = map['quantity'] ?? 0;
      final unitPrice = map['unitPrice'] ?? 
          ((map['total'] ?? 0.0).toDouble() / (quantity > 0 ? quantity : 1));
      
      items = [
        SaleItem(
          productId: productId,
          quantity: quantity,
          unitPrice: unitPrice,
        ),
      ];
    }
    
    return Sale(
      id: id,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      customerId: map['customerId'],
      items: items,
      paymentType: map['paymentType'] ?? 'Cash',
      paymentReceipt: map['paymentReceipt'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Método para crear una copia con cambios
  Sale copyWith({
    String? id,
    DateTime? date,
    String? customerId,
    List<SaleItem>? items,
    String? paymentType,
    String? paymentReceipt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Sale(
      id: id ?? this.id,
      date: date ?? this.date,
      customerId: customerId ?? this.customerId,
      items: items ?? this.items,
      paymentType: paymentType ?? this.paymentType,
      paymentReceipt: paymentReceipt ?? this.paymentReceipt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Sale(id: $id, date: $date, customerId: $customerId, items: ${items.length}, total: $total)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Sale && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
