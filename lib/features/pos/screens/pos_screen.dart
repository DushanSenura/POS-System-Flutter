import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../shared/widgets/custom_buttons.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/employee_access_guard.dart';
import '../../cart/providers/cart_provider.dart';
import '../../products/providers/products_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../scanner/services/barcode_scanner_service.dart';
import '../widgets/cart_item_widget.dart';
import '../widgets/product_grid_item.dart';
import '../widgets/payment_method_dialog.dart';

/// POS Checkout Screen
class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showPaymentDialog() {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      SnackBarHelper.showError(context, 'Cart is empty');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => const PaymentMethodDialog(),
    );
  }

  void _showTaxDialog() {
    final theme = Theme.of(context);
    final settings = ref.read(settingsProvider);
    final currentTaxRate = (settings.taxRate * 100).toStringAsFixed(0);
    final taxController = TextEditingController(text: currentTaxRate);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Tax Rate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the new tax rate percentage',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: taxController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Tax Rate (%)',
                hintText: 'e.g., 10',
                border: OutlineInputBorder(),
                suffixText: '%',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newRate = double.tryParse(taxController.text);
              if (newRate != null && newRate >= 0 && newRate <= 100) {
                ref
                    .read(settingsProvider.notifier)
                    .updateTaxRate(newRate / 100);
                Navigator.pop(context);
                SnackBarHelper.showSuccess(
                  context,
                  'Tax rate updated to $newRate%',
                );
              } else {
                SnackBarHelper.showError(
                  context,
                  'Please enter a valid tax rate (0-100)',
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDiscountDialog() {
    final theme = Theme.of(context);
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      SnackBarHelper.showError(context, 'Cart is empty');
      return;
    }

    final subtotal = ref.read(cartSubtotalProvider);
    final currentDiscount = ref.read(cartDiscountProvider);
    final currentPercentage = subtotal > 0
        ? (currentDiscount / subtotal * 100)
        : 0;

    final discountController = TextEditingController(
      text: currentPercentage.toStringAsFixed(1),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Discount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the discount percentage',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: discountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Discount Percentage',
                hintText: '0',
                border: OutlineInputBorder(),
                suffixText: '%',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final percentage = double.tryParse(discountController.text);

              if (percentage != null && percentage >= 0 && percentage <= 100) {
                // Calculate discount amount from percentage
                final discountAmount = subtotal * (percentage / 100);

                // Distribute discount proportionally across cart items
                final cartNotifier = ref.read(cartProvider.notifier);
                for (final item in cart) {
                  final itemProportion = item.subtotal / subtotal;
                  final itemDiscount = discountAmount * itemProportion;
                  cartNotifier.applyDiscount(item.id, itemDiscount);
                }
                Navigator.pop(context);
                SnackBarHelper.showSuccess(
                  context,
                  'Discount of $percentage% applied (${CurrencyFormatter.format(discountAmount)})',
                );
              } else {
                SnackBarHelper.showError(
                  context,
                  'Please enter a valid discount percentage (0-100)',
                );
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final products = ref.watch(searchedProductsProvider);
    final categories = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final cart = ref.watch(cartProvider);
    final settings = ref.watch(settingsProvider);
    final sortOrder = ref.watch(sortOrderProvider);

    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    return EmployeeAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New Sale'),
          actions: [
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
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () async {
                final barcode = await BarcodeScannerService.showScannerDialog(
                  context,
                );
                if (barcode != null && mounted) {
                  final productsNotifier = ref.read(productsProvider.notifier);
                  final product = productsNotifier.findProductByBarcode(
                    barcode,
                  );

                  if (product != null) {
                    ref.read(cartProvider.notifier).addItem(product);
                  } else {
                    SnackBarHelper.showError(
                      context,
                      'Product not found for barcode: $barcode',
                    );
                  }
                }
              },
              tooltip: 'Scan Barcode',
            ),
          ],
        ),
        body: Row(
          children: [
            // Products section
            Expanded(
              flex: isLargeScreen ? 2 : 1,
              child: Column(
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
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 8,
                      ),
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
                              ref.read(sortOrderProvider.notifier).state =
                                  'None';
                            },
                            backgroundColor: theme.colorScheme.primary
                                .withOpacity(0.1),
                            labelStyle: TextStyle(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Category tabs
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = category == selectedCategory;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (_) {
                              ref
                                      .read(selectedCategoryProvider.notifier)
                                      .state =
                                  category;
                            },
                            backgroundColor: isSelected
                                ? theme.colorScheme.primary
                                : null,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const Divider(height: 1),

                  // Products grid
                  Expanded(
                    child: products.isEmpty
                        ? Center(
                            child: Text(
                              'No products found',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isLargeScreen ? 4 : 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.75,
                                ),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              return ProductGridItem(product: products[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),

            // Cart section
            if (isLargeScreen || cart.isNotEmpty)
              Container(
                width: isLargeScreen ? 400 : MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(left: BorderSide(color: theme.dividerColor)),
                ),
                child: Column(
                  children: [
                    // Cart header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: theme.dividerColor),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Current Order',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          if (cart.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                ref.read(cartProvider.notifier).clearCart();
                              },
                              child: const Text('Clear'),
                            ),
                        ],
                      ),
                    ),

                    // Cart items
                    Expanded(
                      child: cart.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_cart_outlined,
                                    size: 64,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Cart is empty',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: cart.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 24),
                              itemBuilder: (context, index) {
                                return CartItemWidget(cartItem: cart[index]);
                              },
                            ),
                    ),

                    // Cart summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: theme.dividerColor),
                        ),
                      ),
                      child: Column(
                        children: [
                          _SummaryRow(
                            label: 'Subtotal',
                            value: CurrencyFormatter.format(
                              ref.watch(cartSubtotalProvider),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Builder(
                                    builder: (context) {
                                      final subtotal = ref.watch(
                                        cartSubtotalProvider,
                                      );
                                      final discount = ref.watch(
                                        cartDiscountProvider,
                                      );
                                      final percentage = subtotal > 0
                                          ? (discount / subtotal * 100)
                                                .toStringAsFixed(1)
                                          : '0.0';

                                      return Text(
                                        'Discount ($percentage%)',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.normal,
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.7),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: _showDiscountDialog,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Icon(
                                        Icons.edit,
                                        size: 16,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '- ${CurrencyFormatter.format(ref.watch(cartDiscountProvider))}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Tax (${(settings.taxRate * 100).toStringAsFixed(0)}%)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: _showTaxDialog,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Icon(
                                        Icons.edit,
                                        size: 16,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                CurrencyFormatter.format(
                                  ref.watch(cartTaxProvider),
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _SummaryRow(
                            label: 'Total',
                            value: CurrencyFormatter.format(
                              ref.watch(cartTotalProvider),
                            ),
                            isTotal: true,
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            text: 'Proceed to Payment',
                            onPressed: _showPaymentDialog,
                            width: double.infinity,
                            height: 52,
                            icon: Icons.payment,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            color: isTotal
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
