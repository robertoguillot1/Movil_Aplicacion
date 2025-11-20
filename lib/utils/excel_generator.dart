import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/sale.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../services/product_service.dart';
import 'formatters.dart';

class ExcelGenerator {
  static Future<File> generateSalesExcel(
    List<Sale> sales,
    CustomerService customerService,
    ProductService productService,
  ) async {
    // Crear un archivo CSV simple ya que no tenemos la dependencia excel
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/sales_report.csv');
    
    final buffer = StringBuffer();
    buffer.writeln('ID,Cliente,Productos,Fecha,Total,Estado');
    
    for (var sale in sales) {
      final customer = sale.customerId != null ? customerService.getById(sale.customerId!) : Customer.empty();
      final productNames = sale.items.map((item) {
        final product = productService.getById(item.productId);
        return '${product?.name ?? "Producto"} x${item.quantity}';
      }).join('; ');
      
      buffer.writeln([
        sale.id,
        customer.name.isNotEmpty ? customer.name : 'Cliente desconocido',
        productNames.isEmpty ? 'Sin productos' : productNames,
        formatDate(sale.date),
        formatCurrency(sale.total),
        sale.isPending ? 'Pendiente' : 'Pagado'
      ].join(','));
    }
    
    await file.writeAsBytes(utf8.encode(buffer.toString()));
    return file;
  }

  static Future<File?> generateAndSaveExcel(
    List<Sale> sales,
    CustomerService customerService,
    ProductService productService,
  ) async {
    try {
      // Crear archivo temporal primero
      final tempDir = await getTemporaryDirectory();
      final fileName = 'reporte_ventas_${DateTime.now().millisecondsSinceEpoch}.csv';
      final tempFile = File('${tempDir.path}/$fileName');
      
      final buffer = StringBuffer();
      buffer.writeln('ID,Cliente,Producto,Fecha,Total,Estado');
      
      for (var sale in sales) {
        final customer = sale.customerId != null ? customerService.getById(sale.customerId!) : Customer.empty();
        final product = sale.productId != null ? productService.getById(sale.productId!) : null;
        
        buffer.writeln([
          sale.id,
          customer.name.isNotEmpty ? customer.name : 'Cliente desconocido',
          product?.name ?? 'Producto desconocido',
          formatDate(sale.date),
          formatCurrency(sale.total),
          sale.isPending ? 'Pendiente' : 'Pagado'
        ].join(','));
      }
      
      await tempFile.writeAsBytes(utf8.encode(buffer.toString()));
      
      // Usar share_plus para permitir al usuario guardar donde quiera
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'Reporte de ventas - CervezApp',
        subject: 'Reporte de ventas CSV',
      );
      
      return tempFile;
    } catch (e) {
      throw Exception('Error al guardar archivo: $e');
    }
  }

  static Future<void> shareExcel(
    List<Sale> sales,
    CustomerService customerService,
    ProductService productService,
  ) async {
    try {
      // Crear archivo temporal
      final tempDir = await getTemporaryDirectory();
      final fileName = 'reporte_ventas_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${tempDir.path}/$fileName');
      
      final buffer = StringBuffer();
      buffer.writeln('ID,Cliente,Producto,Fecha,Total,Estado');
      
      for (var sale in sales) {
        final customer = sale.customerId != null ? customerService.getById(sale.customerId!) : Customer.empty();
        final product = sale.productId != null ? productService.getById(sale.productId!) : null;
        
        buffer.writeln([
          sale.id,
          customer.name.isNotEmpty ? customer.name : 'Cliente desconocido',
          product?.name ?? 'Producto desconocido',
          formatDate(sale.date),
          formatCurrency(sale.total),
          sale.isPending ? 'Pendiente' : 'Pagado'
        ].join(','));
      }
      
      await file.writeAsBytes(utf8.encode(buffer.toString()));
      
      // Compartir el archivo
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Reporte de ventas - CervezApp',
        subject: 'Reporte de ventas',
      );
    } catch (e) {
      throw Exception('Error al compartir archivo: $e');
    }
  }
}
