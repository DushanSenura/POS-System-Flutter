import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../../../core/data/sample_data.dart';

/// Products state notifier
class ProductsNotifier extends StateNotifier<List<Product>> {
  ProductsNotifier() : super(SampleData.getProducts());

  /// Add a new product
  void addProduct(Product product) {
    state = [...state, product];
  }

  /// Update an existing product
  void updateProduct(Product product) {
    state = [
      for (final p in state)
        if (p.id == product.id) product else p,
    ];
  }

  /// Delete a product
  void deleteProduct(String productId) {
    state = state.where((p) => p.id != productId).toList();
  }

  /// Update product quantity
  void updateQuantity(String productId, int newQuantity) {
    state = [
      for (final p in state)
        if (p.id == productId)
          p.copyWith(quantity: newQuantity, updatedAt: DateTime.now())
        else
          p,
    ];
  }

  /// Search products by name or barcode
  List<Product> searchProducts(String query) {
    if (query.isEmpty) return state;

    final lowerQuery = query.toLowerCase();
    return state.where((p) {
      return p.name.toLowerCase().contains(lowerQuery) ||
          (p.barcode?.contains(query) ?? false);
    }).toList();
  }

  /// Filter products by category
  List<Product> filterByCategory(String category) {
    if (category == 'All') return state;
    return state.where((p) => p.category == category).toList();
  }

  /// Find product by barcode
  Product? findProductByBarcode(String barcode) {
    try {
      return state.firstWhere((product) => product.barcode == barcode);
    } catch (e) {
      return null;
    }
  }

  /// Clear all products
  void clearAll() {
    state = [];
  }
}

/// Products provider
final productsProvider = StateNotifierProvider<ProductsNotifier, List<Product>>(
  (ref) {
    return ProductsNotifier();
  },
);

/// Categories provider
final categoriesProvider = Provider<List<String>>((ref) {
  final categories = SampleData.getCategories();
  // Keep 'All' at the beginning, sort the rest alphabetically
  final allCategory = categories.where((c) => c == 'All').toList();
  final otherCategories = categories.where((c) => c != 'All').toList()..sort();
  return [...allCategory, ...otherCategories];
});

/// Selected category provider
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

/// Filtered products provider
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(productsProvider);
  final category = ref.watch(selectedCategoryProvider);

  if (category == 'All') return products;
  return products.where((p) => p.category == category).toList();
});

/// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Filter type provider (None, Category, Company)
final filterTypeProvider = StateProvider<String>((ref) => 'None');

/// Sort order provider (None, CompanyAsc, CategoryAsc)
final sortOrderProvider = StateProvider<String>((ref) => 'None');

/// Searched products provider
final searchedProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(filteredProductsProvider);
  final query = ref.watch(searchQueryProvider);
  final sortOrder = ref.watch(sortOrderProvider);

  // First, apply search filter
  List<Product> result = products;
  if (query.isNotEmpty) {
    final lowerQuery = query.toLowerCase();
    result = products.where((p) {
      return p.name.toLowerCase().contains(lowerQuery) ||
          (p.barcode?.contains(query) ?? false) ||
          p.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Then, apply sorting
  if (sortOrder == 'CompanyAsc') {
    result.sort((a, b) {
      final companyA = a.companyName ?? '';
      final companyB = b.companyName ?? '';
      return companyA.toLowerCase().compareTo(companyB.toLowerCase());
    });
  } else if (sortOrder == 'CategoryAsc') {
    result.sort((a, b) => a.category.compareTo(b.category));
  }

  return result;
});
