import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/cart_item_model.dart';
import '../../products/models/product_model.dart';
import '../../settings/providers/settings_provider.dart';

const _uuid = Uuid();

/// Cart state notifier
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier(this.ref) : super([]);

  final Ref ref;

  /// Add item to cart
  void addItem(Product product, {int quantity = 1}) {
    // Check if product already in cart
    final existingIndex = state.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      // Update quantity
      final existingItem = state[existingIndex];
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            existingItem.copyWith(quantity: existingItem.quantity + quantity)
          else
            state[i],
      ];
    } else {
      // Add new item
      final cartItem = CartItem(
        id: _uuid.v4(),
        product: product,
        quantity: quantity,
        addedAt: DateTime.now(),
      );
      state = [...state, cartItem];
    }
  }

  /// Remove item from cart
  void removeItem(String itemId) {
    state = state.where((item) => item.id != itemId).toList();
  }

  /// Update item quantity
  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }

    state = [
      for (final item in state)
        if (item.id == itemId) item.copyWith(quantity: quantity) else item,
    ];
  }

  /// Apply discount to item
  void applyDiscount(String itemId, double discount) {
    state = [
      for (final item in state)
        if (item.id == itemId) item.copyWith(discount: discount) else item,
    ];
  }

  /// Clear cart
  void clearCart() {
    state = [];
  }

  /// Get cart total before tax
  double get subtotal {
    return state.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  /// Get total discount
  double get totalDiscount {
    return state.fold(0.0, (sum, item) => sum + item.discount);
  }

  /// Get cart total after discount and tax
  double getTotal() {
    final settings = ref.read(settingsProvider);
    final subtotalAfterDiscount = subtotal - totalDiscount;
    final taxAmount = subtotalAfterDiscount * settings.taxRate;
    return subtotalAfterDiscount + taxAmount;
  }

  /// Get tax amount
  double getTax() {
    final settings = ref.read(settingsProvider);
    final subtotalAfterDiscount = subtotal - totalDiscount;
    return subtotalAfterDiscount * settings.taxRate;
  }
}

/// Cart provider
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier(ref);
});

/// Cart item count provider
final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantity);
});

/// Cart subtotal provider
final cartSubtotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0.0, (sum, item) => sum + item.subtotal);
});

/// Cart total provider
final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  final settings = ref.watch(settingsProvider);

  final subtotal = cart.fold(0.0, (sum, item) => sum + item.subtotal);
  final discount = cart.fold(0.0, (sum, item) => sum + item.discount);
  final subtotalAfterDiscount = subtotal - discount;
  final tax = subtotalAfterDiscount * settings.taxRate;

  return subtotalAfterDiscount + tax;
});

/// Cart tax provider
final cartTaxProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  final settings = ref.watch(settingsProvider);

  final subtotal = cart.fold(0.0, (sum, item) => sum + item.subtotal);
  final discount = cart.fold(0.0, (sum, item) => sum + item.discount);
  final subtotalAfterDiscount = subtotal - discount;

  return subtotalAfterDiscount * settings.taxRate;
});

/// Cart discount provider
final cartDiscountProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0.0, (sum, item) => sum + item.discount);
});
