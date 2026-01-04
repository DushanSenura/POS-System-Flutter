import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Provider for managing product categories
final categoryProvider = StateNotifierProvider<CategoryNotifier, List<String>>((
  ref,
) {
  return CategoryNotifier();
});

/// Notifier for managing product categories
class CategoryNotifier extends StateNotifier<List<String>> {
  static const String _boxName = 'categories';
  Box<dynamic>? _box;

  CategoryNotifier() : super([]) {
    _init();
  }

  /// Initialize and load categories from Hive
  Future<void> _init() async {
    // Get the already-opened box
    _box = Hive.box(_boxName);
    final savedCategories = _box?.get(
      'categoryList',
      defaultValue: _defaultCategories,
    );
    state = List<String>.from(savedCategories ?? _defaultCategories);
  }

  /// Default categories
  static const List<String> _defaultCategories = [
    'Beverages',
    'Food',
    'Bakery',
    'Snacks',
    'Other',
  ];

  /// Add a new category
  Future<void> addCategory(String category) async {
    final trimmedCategory = category.trim();
    if (trimmedCategory.isEmpty) return;

    // Check if category already exists (case-insensitive)
    if (state.any(
      (cat) => cat.toLowerCase() == trimmedCategory.toLowerCase(),
    )) {
      return;
    }

    state = [...state, trimmedCategory];
    await _saveCategories();
  }

  /// Remove a category
  Future<void> removeCategory(String category) async {
    state = state.where((cat) => cat != category).toList();
    await _saveCategories();
  }

  /// Update a category name
  Future<void> updateCategory(String oldName, String newName) async {
    final trimmedNewName = newName.trim();
    if (trimmedNewName.isEmpty) return;

    final index = state.indexOf(oldName);
    if (index == -1) return;

    final updatedList = [...state];
    updatedList[index] = trimmedNewName;
    state = updatedList;
    await _saveCategories();
  }

  /// Reset to default categories
  Future<void> resetToDefault() async {
    state = [..._defaultCategories];
    await _saveCategories();
  }

  /// Save categories to Hive
  Future<void> _saveCategories() async {
    await _box?.put('categoryList', state);
  }
}

/// Provider for sorted categories
final sortedCategoriesProvider = Provider<List<String>>((ref) {
  final categories = ref.watch(categoryProvider);
  return [...categories]..sort();
});
