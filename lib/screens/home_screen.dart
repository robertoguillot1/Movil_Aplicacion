// v1.6 - screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_colors.dart';
import '../services/product_service.dart';
import '../services/sales_service.dart';
import '../services/customer_service.dart';
import '../services/stats_service.dart';
import '../services/auth_service.dart';
import '../models/customer.dart';
import 'auth/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🍻 CervezApp"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          Consumer<AuthService>(
            builder: (context, authService, child) {
              return PopupMenuButton<String>(
                icon: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    authService.currentUser?.fullName.isNotEmpty == true 
                        ? authService.currentUser!.fullName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onSelected: (String value) {
                  if (value == 'profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Icons.person),
                        const SizedBox(width: 8),
                        Text(authService.currentUser?.fullName ?? 'Usuario'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'role',
                    enabled: false,
                    child: Text(
                      authService.currentUser?.isAdmin == true ? 'Administrador' : 'Trabajador',
                      style: TextStyle(
                        color: authService.currentUser?.isAdmin == true ? Colors.red : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Consumer4<ProductService, SalesService, CustomerService, StatsService>(
        builder: (context, productService, salesService, customerService, statsService, child) {
          final outOfStockProducts = productService.products.where((p) => p.stock == 0).toList();
          final lowStockProducts = productService.getLowStockProducts();
          final recentSales = salesService.sales.take(5).toList();
          final pendingPayments = salesService.sales.where((s) => s.isPending).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Resumen general
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📊 Resumen General',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                '💰 Ingresos',
                                '\$${statsService.totalRevenue.toStringAsFixed(0)}',
                                Icons.monetization_on,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCard(
                                '📦 Ventas',
                                '${statsService.totalUnitsSold}',
                                Icons.shopping_cart,
                                Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                '🏪 Productos',
                                '${statsService.totalProducts}',
                                Icons.inventory,
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCard(
                                '👥 Clientes',
                                '${customerService.customers.length}',
                                Icons.people,
                                Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Productos sin stock
                if (outOfStockProducts.isNotEmpty) ...[
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Text(
                                '⚠️ Productos Sin Stock',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...outOfStockProducts.map((product) => ListTile(
                            leading: const Icon(Icons.local_drink, color: Colors.red),
                            title: Text(product.name),
                            subtitle: Text('Precio: \$${product.price.toStringAsFixed(0)}'),
                            trailing: ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/product/edit', arguments: product);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Surtr'),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Productos con bajo stock
                if (lowStockProducts.isNotEmpty) ...[
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber, color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              Text(
                                '⚠️ Bajo Stock',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...lowStockProducts.map((product) => ListTile(
                            leading: const Icon(Icons.local_drink, color: Colors.orange),
                            title: Text(product.name),
                            subtitle: Text('Stock: ${product.stock} | Precio: \$${product.price.toStringAsFixed(0)}'),
                            trailing: ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/product/edit', arguments: product);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Revisar'),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Pagos pendientes
                if (pendingPayments > 0) ...[
                  Card(
                    color: Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.pending, color: Colors.amber.shade700),
                              const SizedBox(width: 8),
                              Text(
                                '💳 Pagos Pendientes',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Tienes $pendingPayments ventas con pagos pendientes'),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/sales');
                            },
                            icon: const Icon(Icons.payment),
                            label: const Text('Ver Ventas'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Ventas recientes
                if (recentSales.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.history),
                              const SizedBox(width: 8),
                              const Text(
                                '🕒 Ventas Recientes',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/sales');
                                },
                                child: const Text('Ver Todas'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...recentSales.map((sale) {
                            final firstProduct = sale.items.isNotEmpty 
                                ? productService.getById(sale.items.first.productId) 
                                : null;
                            final customer = sale.customerId != null ? customerService.getById(sale.customerId!) : Customer.empty();
                            final productCount = sale.items.length;
                            final productName = productCount == 1
                                ? (firstProduct?.name ?? 'Producto desconocido')
                                : '$productCount productos';
                            return ListTile(
                              leading: const Icon(Icons.receipt),
                              title: Text(productName),
                              subtitle: Text(
                                '${customer.name.isNotEmpty ? customer.name : "Anónimo"} - \$${sale.total.toStringAsFixed(0)}',
                              ),
                              trailing: sale.isPending 
                                ? const Icon(Icons.pending, color: Colors.orange)
                                : const Icon(Icons.check_circle, color: Colors.green),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],

                // Mensaje de bienvenida si no hay datos
                if (outOfStockProducts.isEmpty && lowStockProducts.isEmpty && pendingPayments == 0 && recentSales.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(Icons.emoji_emotions, size: 64, color: Colors.green),
                          const SizedBox(height: 16),
                          const Text(
                            '¡Todo en orden! 🎉',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No hay productos sin stock, pagos pendientes o alertas.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/sale/new');
                            },
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text('Registrar Primera Venta'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
