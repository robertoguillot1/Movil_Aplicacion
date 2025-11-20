// v1.6 - screens/product/product_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/product_service.dart';
import '../../models/product.dart';
import '../../theme/app_colors.dart';
import '../../services/category_service.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Todas';
  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts() {
    final productService = Provider.of<ProductService>(context, listen: false);
    final allProducts = productService.products;
    
    setState(() {
      _filteredProducts = allProducts.where((product) {
        // Filtro por categoría
        final categoryMatch = _selectedCategory == 'Todas' || 
            (product.category == null && _selectedCategory == 'Sin categoría') ||
            (product.category != null && product.category == _selectedCategory);
        
        // Filtro por búsqueda
        final searchQuery = _searchController.text.toLowerCase();
        final searchMatch = searchQuery.isEmpty ||
            product.name.toLowerCase().contains(searchQuery) ||
            (product.category != null && product.category!.toLowerCase().contains(searchQuery));
        
        return categoryMatch && searchMatch;
      }).toList();
    });
  }

  static void _showDeleteDialog(BuildContext context, Product product, ProductService productService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🗑️ Eliminar Producto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¿Estás seguro de que quieres eliminar este producto?'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📦 ${product.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('💰 Precio: \$${product.price.toStringAsFixed(0)}'),
                    Text('📊 Stock: ${product.stock} unidades'),
                    Text('💵 Valor: \$${(product.price * product.stock).toStringAsFixed(0)}'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '⚠️ Esta acción no se puede deshacer.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (product.id != null) {
                  productService.deleteProduct(product.id!);
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  static void _showIncreaseStockDialog(BuildContext context, Product product, ProductService productService) {
    final quantityController = TextEditingController(text: '10');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('📦 Aumentar Stock - ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Stock actual: ${product.stock} unidades'),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad a agregar',
                  hintText: 'Ej: 10',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final quantity = int.tryParse(quantityController.text);
                if (quantity != null && quantity > 0 && product.id != null) {
                  productService.increaseStock(product.id!, quantity);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productService = Provider.of<ProductService>(context);
    final products = productService.products;
    
    // Actualizar productos filtrados si no están inicializados
    if (_filteredProducts.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _filterProducts();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventario de Productos"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          Consumer<ProductService>(
            builder: (context, productService, child) {
              return IconButton(
                icon: productService.isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh),
                onPressed: productService.isLoading ? null : () {
                  productService.refreshProducts();
                },
                tooltip: 'Refrescar productos',
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.secondary,
        onPressed: () {
          Navigator.pushNamed(context, '/product/new');
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                // Barra de búsqueda
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar productos...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Filtro por categoría
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip('Todas', Icons.all_inclusive),
                      _buildCategoryChip('Sin categoría', Icons.category),
                      ...CategoryService.getAvailableCategories().map(
                        (category) => _buildCategoryChip(
                          category,
                          CategoryService.getCategoryIcon(category),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Contador de resultados
                const SizedBox(height: 8),
                Text(
                  'Mostrando ${_filteredProducts.length} de ${products.length} productos',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de productos
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron productos',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Intenta ajustar los filtros o la búsqueda',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, i) {
                      final Product p = _filteredProducts[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CategoryService.getCategoryColor(p.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: CategoryService.getCategoryColor(p.category).withOpacity(0.3),
                  ),
                ),
                child: Icon(
                  CategoryService.getCategoryIcon(p.category),
                  color: CategoryService.getCategoryColor(p.category),
                  size: 24,
                ),
              ),
              title: Text(p.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Precio: \$${p.price.toStringAsFixed(0)} | Stock: ${p.stock}"),
                  if (p.category != null && p.category!.isNotEmpty)
                    Text(
                      CategoryService.getFormattedCategoryName(p.category),
                      style: TextStyle(
                        color: CategoryService.getCategoryColor(p.category),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  if (p.stock == 0)
                    const Text("🚨 AGOTADO", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                  else if (p.isLowStock)
                    const Text("⚠️ Bajo Stock", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (p.stock <= 5)
                    IconButton(
                      icon: const Icon(Icons.add_box, color: Colors.green),
                      onPressed: () => _showIncreaseStockDialog(context, p, productService),
                      tooltip: 'Aumentar Stock',
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    onPressed: () {
                      Navigator.pushNamed(context, '/product/edit', arguments: p);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _showDeleteDialog(context, p, productService);
                    },
                  ),
                ],
              ),
            ),
          );
                    },
                  ),
                ),

        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category, IconData icon) {
    final isSelected = _selectedCategory == category;
    final color = category == 'Todas' 
        ? Colors.blue 
        : category == 'Sin categoría' 
            ? Colors.grey 
            : CategoryService.getCategoryColor(category);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : color),
            const SizedBox(width: 4),
            Text(category),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
          _filterProducts();
        },
        selectedColor: color,
        checkmarkColor: Colors.white,
        backgroundColor: color.withOpacity(0.1),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
    );
  }
}
