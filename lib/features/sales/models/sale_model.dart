import 'package:hive/hive.dart';
import '../../cart/models/cart_item_model.dart';

part 'sale_model.g.dart';

/// Sale model representing completed transactions
@HiveType(typeId: 2)
class Sale {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final List<CartItem> items;

  @HiveField(2)
  final double subtotal;

  @HiveField(3)
  final double tax;

  @HiveField(4)
  final double discount;

  @HiveField(5)
  final double total;

  @HiveField(6)
  final String paymentMethod;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final String? cashierName;

  @HiveField(9)
  final String? customerName;

  @HiveField(10)
  final String? notes;

  @HiveField(11)
  final int? printCount;

  Sale({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.createdAt,
    this.cashierName,
    this.customerName,
    this.notes,
    this.printCount = 0,
  });

  /// Get print count safely (never returns null)
  int get safePrintCount => printCount ?? 0;

  /// Create a copy with modified fields
  Sale copyWith({
    String? id,
    List<CartItem>? items,
    double? subtotal,
    double? tax,
    double? discount,
    double? total,
    String? paymentMethod,
    DateTime? createdAt,
    String? cashierName,
    String? customerName,
    String? notes,
    int? printCount,
  }) {
    return Sale(
      id: id ?? this.id,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      cashierName: cashierName ?? this.cashierName,
      customerName: customerName ?? this.customerName,
      notes: notes ?? this.notes,
      printCount: printCount ?? this.printCount,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      'cashierName': cashierName,
      'customerName': customerName,
      'notes': notes,
      'printCount': printCount,
    };
  }

  /// Create from JSON
  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'] as String,
      items: (json['items'] as List)
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      cashierName: json['cashierName'] as String?,
      customerName: json['customerName'] as String?,
      notes: json['notes'] as String?,
      printCount: (json['printCount'] as int?) ?? 0,
    );
  }
}
