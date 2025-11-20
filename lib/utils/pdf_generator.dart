import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/sale.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../services/product_service.dart';
import 'formatters.dart';

class PdfGenerator {
  static Future<File> generateSalesReport(
    List<Sale> sales,
    CustomerService customerService,
    ProductService productService,
  ) async {
    // Crear un archivo de texto simple ya que no tenemos la dependencia pdf
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/sales_report.txt');
    
    final buffer = StringBuffer();
    buffer.writeln('=== REPORTE DE VENTAS ===');
    buffer.writeln('Generado: ${formatDate(DateTime.now())}');
    buffer.writeln('');
    buffer.writeln('ID\tCliente\tProductos\tFecha\tTotal\tEstado');
    buffer.writeln('-' * 80);
    
    for (var sale in sales) {
      final customer = sale.customerId != null ? customerService.getById(sale.customerId!) : Customer.empty();
      final productNames = sale.items.map((item) {
        final product = productService.getById(item.productId);
        return '${product?.name ?? "Producto"} x${item.quantity}';
      }).join(', ');
      
      buffer.writeln([
        sale.id,
        customer.name.isNotEmpty ? customer.name : 'Cliente desconocido',
        productNames.isEmpty ? 'Sin productos' : productNames,
        formatDate(sale.date),
        formatCurrency(sale.total),
        sale.isPending ? 'Pendiente' : 'Pagado'
      ].join('\t'));
    }
    
    buffer.writeln('');
    buffer.writeln('Total de ventas: ${sales.length}');
    buffer.writeln('Total ingresos: ${formatCurrency(sales.fold(0.0, (sum, sale) => sum + sale.total))}');
    
    await file.writeAsBytes(utf8.encode(buffer.toString()));
    return file;
  }

  static Future<File?> generateAndSavePdf(
    List<Sale> sales,
    CustomerService customerService,
    ProductService productService,
  ) async {
    try {
      // Crear archivo temporal primero
      final tempDir = await getTemporaryDirectory();
      final fileName = 'reporte_ventas_${DateTime.now().millisecondsSinceEpoch}.txt';
      final tempFile = File('${tempDir.path}/$fileName');
      
      final buffer = StringBuffer();
      buffer.writeln('=== REPORTE DE VENTAS ===');
      buffer.writeln('Generado: ${formatDate(DateTime.now())}');
      buffer.writeln('');
      buffer.writeln('ID\tCliente\tProductos\tFecha\tTotal\tEstado');
      buffer.writeln('-' * 80);
      
      for (var sale in sales) {
        final customer = sale.customerId != null ? customerService.getById(sale.customerId!) : Customer.empty();
        final productNames = sale.items.map((item) {
          final product = productService.getById(item.productId);
          return '${product?.name ?? "Producto"} x${item.quantity}';
        }).join(', ');
        
        buffer.writeln([
          sale.id,
          customer.name.isNotEmpty ? customer.name : 'Cliente desconocido',
          productNames.isEmpty ? 'Sin productos' : productNames,
          formatDate(sale.date),
          formatCurrency(sale.total),
          sale.isPending ? 'Pendiente' : 'Pagado'
        ].join('\t'));
      }
      
      buffer.writeln('');
      buffer.writeln('Total de ventas: ${sales.length}');
      buffer.writeln('Total ingresos: ${formatCurrency(sales.fold(0.0, (sum, sale) => sum + sale.total))}');
      
      await tempFile.writeAsBytes(utf8.encode(buffer.toString()));
      
      // Usar share_plus para permitir al usuario guardar donde quiera
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'Reporte de ventas - CervezApp',
        subject: 'Reporte de ventas TXT',
      );
      
      return tempFile;
    } catch (e) {
      throw Exception('Error al guardar archivo: $e');
    }
  }

  static Future<void> sharePdf(
    List<Sale> sales,
    CustomerService customerService,
    ProductService productService,
  ) async {
    try {
      // Crear archivo temporal
      final tempDir = await getTemporaryDirectory();
      final fileName = 'reporte_ventas_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${tempDir.path}/$fileName');
      
      final buffer = StringBuffer();
      buffer.writeln('=== REPORTE DE VENTAS ===');
      buffer.writeln('Generado: ${formatDate(DateTime.now())}');
      buffer.writeln('');
      buffer.writeln('ID\tCliente\tProductos\tFecha\tTotal\tEstado');
      buffer.writeln('-' * 80);
      
      for (var sale in sales) {
        final customer = sale.customerId != null ? customerService.getById(sale.customerId!) : Customer.empty();
        final productNames = sale.items.map((item) {
          final product = productService.getById(item.productId);
          return '${product?.name ?? "Producto"} x${item.quantity}';
        }).join(', ');
        
        buffer.writeln([
          sale.id,
          customer.name.isNotEmpty ? customer.name : 'Cliente desconocido',
          productNames.isEmpty ? 'Sin productos' : productNames,
          formatDate(sale.date),
          formatCurrency(sale.total),
          sale.isPending ? 'Pendiente' : 'Pagado'
        ].join('\t'));
      }
      
      buffer.writeln('');
      buffer.writeln('Total de ventas: ${sales.length}');
      buffer.writeln('Total ingresos: ${formatCurrency(sales.fold(0.0, (sum, sale) => sum + sale.total))}');
      
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
