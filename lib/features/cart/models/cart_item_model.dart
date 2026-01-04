import 'package:hive/hive.dart';
import '../../products/models/product_model.dart';

part 'cart_item_model.g.dart';

/// Cart item model representing items in the shopping cart
@HiveType(typeId: 1)
class CartItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final Product product;

  @HiveField(2)
  final int quantity;

  @HiveField(3)
  final double discount;

  @HiveField(4)
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    this.discount = 0.0,
    required this.addedAt,
  });

  /// Calculate subtotal for this item
  double get subtotal => product.price * quantity;

  /// Calculate total after discount
  double get total => subtotal - discount;

  /// Create a copy with modified fields
  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    double? discount,
    DateTime? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'discount': discount,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }
}
