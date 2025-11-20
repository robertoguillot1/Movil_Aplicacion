// v1.6 - main.dart
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart' show DefaultFirebaseOptions;
import 'theme/app_theme.dart';
import 'services/product_service.dart';
import 'services/customer_service.dart';
import 'services/sales_service.dart';
import 'services/stats_service.dart';
import 'services/auth_service.dart';
import 'services/developer_service.dart';
import 'models/product.dart';
import 'screens/home_screen.dart';
import 'screens/product/product_list_screen.dart';
import 'screens/product/product_form_screen.dart';
import 'screens/customers/customers_screen.dart';
import 'screens/customers/customer_form.dart';
import 'screens/sales/sales_screen.dart';
import 'screens/sales/sale_form.dart';
import 'screens/stats/stats_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/profile_screen.dart';
import 'screens/about_screen.dart';
import 'screens/developer_panel_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Inicializamos los servicios base fuera de runApp para pasarlos a MultiProvider
  final authService = AuthService();
  final productService = ProductService();
  final customerService = CustomerService();
  final salesService = SalesService(
    productService: productService,
    customerService: customerService,
  );
  final statsService = StatsService(
    productService: productService,
    salesService: salesService,
  );
  final developerService = DeveloperService(authService);

  // Establecer las referencias de servicios en AuthService
  authService.setServices(
    productService: productService,
    customerService: customerService,
    salesService: salesService,
  );

  // Inicializar datos por defecto
  await authService.initializeDefaultAdmin();
  await productService.initializeDefaultProducts();
  await customerService.initializeDefaultCustomers();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: productService),
        ChangeNotifierProvider.value(value: customerService),
        ChangeNotifierProvider.value(value: salesService),
        ChangeNotifierProvider.value(value: statsService),
        ChangeNotifierProvider.value(value: developerService),
      ],
      child: const CervezApp(),
    ),
  );
}

class CervezApp extends StatelessWidget {
  const CervezApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'CervezApp v1.6',
          theme: AppTheme.lightTheme,
          home: authService.isAuthenticated ? const HomeScreen() : const LoginScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/products': (context) => const ProductListScreen(),
            '/product/new': (context) => const ProductFormScreen(),
            '/product/edit': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              return ProductFormScreen(product: args as Product?);
            },
            '/customers': (context) => const CustomersScreen(),
            '/customer/new': (context) => const CustomerForm(),
            '/customer/edit': (context) => const CustomerForm(),
            '/sales': (context) => const SalesScreen(),
            '/sale/new': (context) => const SaleFormScreen(),
            '/stats': (context) => const StatsScreen(),
            '/about': (context) => const AboutScreen(),
            '/developer': (context) => const DeveloperPanelScreen(),
          },
        );
      },
    );
  }
}
