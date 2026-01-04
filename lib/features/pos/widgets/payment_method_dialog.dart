import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../shared/widgets/custom_buttons.dart';
import '../../cart/models/cart_item_model.dart';
import '../../cart/providers/cart_provider.dart';
import '../../sales/providers/sales_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../products/providers/products_provider.dart';
import 'receipt_preview_dialog.dart';

/// Payment method selection dialog
class PaymentMethodDialog extends ConsumerStatefulWidget {
  const PaymentMethodDialog({super.key});

  @override
  ConsumerState<PaymentMethodDialog> createState() =>
      _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends ConsumerState<PaymentMethodDialog> {
  String _selectedMethod = AppConstants.paymentCash;

  void _completeSale() {
    final cart = ref.read(cartProvider);
    final subtotal = ref.read(cartSubtotalProvider);
    final tax = ref.read(cartTaxProvider);
    final discount = ref.read(cartDiscountProvider);
    final total = ref.read(cartTotalProvider);
    final currentUser = ref.read(currentUserProvider);

    // Deduct stock from products
    final productsNotifier = ref.read(productsProvider.notifier);
    for (final item in cart) {
      final newQuantity = item.product.quantity - item.quantity;
      if (newQuantity < 0) {
        // Show error if stock is insufficient
        SnackBarHelper.showError(
          context,
          'Insufficient stock for ${item.product.name}',
        );
        return;
      }
      productsNotifier.updateQuantity(item.product.id, newQuantity);
    }

    // Store cart data before clearing
    final cartItems = List<CartItem>.from(cart);

    // Add sale and get sale ID
    final saleId = ref
        .read(salesProvider.notifier)
        .addSale(
          items: cart,
          subtotal: subtotal,
          tax: tax,
          discount: discount,
          total: total,
          paymentMethod: _selectedMethod,
          cashierName: currentUser?.name,
        );

    // Clear cart
    ref.read(cartProvider.notifier).clearCart();

    // Close payment dialog
    Navigator.of(context).pop();

    // Show receipt preview (stay on POS screen)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReceiptPreviewDialog(
        saleId: saleId,
        items: cartItems,
        subtotal: subtotal,
        discount: discount,
        tax: tax,
        total: total,
        paymentMethod: _selectedMethod,
        cashierName: currentUser?.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentMethods = [
      AppConstants.paymentCash,
      AppConstants.paymentCard,
      AppConstants.paymentQR,
      AppConstants.paymentWallet,
    ];

    final icons = {
      AppConstants.paymentCash: Icons.payments_outlined,
      AppConstants.paymentCard: Icons.credit_card,
      AppConstants.paymentQR: Icons.qr_code,
      AppConstants.paymentWallet: Icons.account_balance_wallet_outlined,
    };

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text(
                  'Select Payment Method',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Payment method options
            ...paymentMethods.map((method) {
              final isSelected = method == _selectedMethod;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedMethod = method;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.veryLightGrey,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icons[method],
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          method,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    text: 'Complete Sale',
                    onPressed: _completeSale,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
