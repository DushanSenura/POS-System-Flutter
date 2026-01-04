import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/products_provider.dart';
import 'product_form_screen.dart';

/// Products management screen
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchController = TextEditingController();

  void _showFilterDialog() {
    final currentSort = ref.read(sortOrderProvider);
    String selectedSort = currentSort;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter & Sort Products'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sort By:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 12),
                RadioListTile<String>(
                  title: const Text('None'),
                  value: 'None',
                  groupValue: selectedSort,
                  onChanged: (value) {
                    setState(() {
                      selectedSort = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                RadioListTile<String>(
                  title: const Text('Company Name (A-Z)'),
                  value: 'CompanyAsc',
                  groupValue: selectedSort,
                  onChanged: (value) {
                    setState(() {
                      selectedSort = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                RadioListTile<String>(
                  title: const Text('Category (A-Z)'),
                  value: 'CategoryAsc',
                  groupValue: selectedSort,
                  onChanged: (value) {
                    setState(() {
                      selectedSort = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (selectedSort != 'None')
            TextButton(
              onPressed: () {
                ref.read(sortOrderProvider.notifier).state = 'None';
                Navigator.pop(context);
              },
              child: const Text('Clear'),
            ),
          ElevatedButton(
            onPressed: () {
              ref.read(sortOrderProvider.notifier).state = selectedSort;
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Products'),
        content: const Text(
          'Are you sure you want to delete all products? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Clear all products
              final productsNotifier = ref.read(productsProvider.notifier);
              final allProducts = ref.read(productsProvider);

              for (final product in allProducts) {
                productsNotifier.deleteProduct(product.id);
              }

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All products cleared successfully'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final products = ref.watch(searchedProductsProvider);
    final sortOrder = ref.watch(sortOrderProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = currentUser?.role.toLowerCase() == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          // Clear Data button (Admin only)
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showClearDataDialog(context),
              tooltip: 'Clear All Data',
            ),
          // Filter button
          IconButton(
            icon: Icon(
              sortOrder != 'None'
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
              color: sortOrder != 'None' ? theme.colorScheme.primary : null,
            ),
            onPressed: _showFilterDialog,
            tooltip: 'Filter & Sort',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchTextField(
              controller: _searchController,
              hint: 'Search products...',
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
              onClear: () {
                ref.read(searchQueryProvider.notifier).state = '';
              },
            ),
          ),

          // Active filter chip
          if (sortOrder != 'None')
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Row(
                children: [
                  Chip(
                    avatar: const Icon(Icons.filter_alt, size: 18),
                    label: Text(
                      sortOrder == 'CompanyAsc'
                          ? 'Sorted by Company'
                          : 'Sorted by Category',
                      style: const TextStyle(fontSize: 12),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      ref.read(sortOrderProvider.notifier).state = 'None';
                    },
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    labelStyle: TextStyle(color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),

          // Products list
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Text(
                      'No products found',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const Divider(height: 24),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final isLowStock = product.quantity < 10;

                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          onTap: () {
                            // Navigate to edit product
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductFormScreen(product: product),
                              ),
                            );
                          },
                          leading: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              image: product.imageUrl != null
                                  ? DecorationImage(
                                      image: FileImage(File(product.imageUrl!)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: product.imageUrl == null
                                ? Icon(
                                    Icons.image_outlined,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.3),
                                  )
                                : null,
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              if (product.companyName != null) ...[
                                Row(
                                  children: [
                                    Icon(
                                      Icons.business,
                                      size: 14,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.5),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        product.companyName!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.6),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                              ],
                              Chip(
                                label: Text(product.category),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(product.price),
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isLowStock
                                      ? Colors.red.withOpacity(0.1)
                                      : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Stock: ${product.quantity}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isLowStock
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProductFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }
}
