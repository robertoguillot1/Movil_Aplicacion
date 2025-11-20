// v1.6 - services/stats_service.dart
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/sale.dart';
import 'product_service.dart';
import 'sales_service.dart';

class StatsService extends ChangeNotifier {
  final ProductService productService;
  final SalesService salesService;

  StatsService({
    required this.productService,
    required this.salesService,
  });

  double get totalRevenue => salesService.totalRevenue;

  int get totalUnitsSold => salesService.totalUnitsSold;

  int get totalProducts => productService.products.length;

  double get totalInventoryValue => productService.totalInventoryValue;

  double get averageProductPrice => productService.averagePrice;

  List<Product> get lowStockProducts => productService.getLowStockProducts();

  Map<String, double> get revenueByProduct => salesService.revenueByProduct;

  /// Historial mensual de ventas (simulación)
  Map<String, double> get monthlySales {
    final Map<String, double> data = {};
    for (var sale in salesService.sales) {
      final key = "${sale.date.month}/${sale.date.year}";
      data[key] = (data[key] ?? 0) + sale.total;
    }
    return data;
  }

  List<Sale> get recentSales {
    final all = salesService.sales;
    all.sort((a, b) => b.date.compareTo(a.date));
    return all.take(10).toList();
  }

  void refresh() {
    notifyListeners();
  }
}
