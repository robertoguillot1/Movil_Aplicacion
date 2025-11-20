// v1.6 - services/category_service.dart
import 'package:flutter/material.dart';

class CategoryService {
  static const Map<String, IconData> _categoryIcons = {
    'bebidas': Icons.local_bar,
    'cervezas': Icons.local_drink,
    'snack': Icons.fastfood,
  };

  static const Map<String, Color> _categoryColors = {
    'bebidas': Colors.blue,
    'cervezas': Colors.amber,
    'snack': Colors.orange,
  };

  /// Obtiene el icono para una categoría
  static IconData getCategoryIcon(String? category) {
    if (category == null || category.isEmpty) {
      return Icons.category;
    }
    
    final normalizedCategory = category.toLowerCase().trim();
    return _categoryIcons[normalizedCategory] ?? Icons.category;
  }

  /// Obtiene el color para una categoría
  static Color getCategoryColor(String? category) {
    if (category == null || category.isEmpty) {
      return Colors.grey;
    }
    
    final normalizedCategory = category.toLowerCase().trim();
    return _categoryColors[normalizedCategory] ?? Colors.grey;
  }

  /// Obtiene todas las categorías disponibles
  static List<String> getAvailableCategories() {
    return ['bebidas', 'cervezas', 'snack'];
  }

  /// Obtiene sugerencias de categorías basadas en el texto ingresado
  static List<String> getCategorySuggestions(String query) {
    if (query.isEmpty) return getAvailableCategories();
    
    final normalizedQuery = query.toLowerCase().trim();
    return getAvailableCategories()
        .where((category) => category.contains(normalizedQuery))
        .toList();
  }

  /// Valida si una categoría es válida
  static bool isValidCategory(String? category) {
    if (category == null || category.isEmpty) return true; // Categoría vacía es válida
    return getAvailableCategories().contains(category.toLowerCase().trim());
  }

  /// Obtiene el nombre formateado de la categoría
  static String getFormattedCategoryName(String? category) {
    if (category == null || category.isEmpty) return 'Sin categoría';
    
    final normalizedCategory = category.toLowerCase().trim();
    return normalizedCategory.isEmpty ? 'Sin categoría' : category;
  }
}


