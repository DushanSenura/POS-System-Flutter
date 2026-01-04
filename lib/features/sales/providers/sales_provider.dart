import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../models/sale_model.dart';
import '../../cart/models/cart_item_model.dart';

final _random = Random();

/// Generate a sale number in format: ABC12345 (3 letters + 5 numbers)
String _generateSaleNumber() {
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  final letter1 = letters[_random.nextInt(letters.length)];
  final letter2 = letters[_random.nextInt(letters.length)];
  final letter3 = letters[_random.nextInt(letters.length)];

  final numbers = _random.nextInt(100000).toString().padLeft(5, '0');

  return '$letter1$letter2$letter3$numbers';
}

/// Sales state notifier
class SalesNotifier extends StateNotifier<List<Sale>> {
  SalesNotifier() : super([]);

  /// Add a new sale
  String addSale({
    required List<CartItem> items,
    required double subtotal,
    required double tax,
    required double discount,
    required double total,
    required String paymentMethod,
    String? cashierName,
    String? customerName,
    String? notes,
  }) {
    final saleNumber = _generateSaleNumber();
    final sale = Sale(
      id: saleNumber,
      items: items,
      subtotal: subtotal,
      tax: tax,
      discount: discount,
      total: total,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
      cashierName: cashierName,
      customerName: customerName,
      notes: notes,
    );

    state = [sale, ...state];
    return sale.id;
  }

  /// Increment print count for a sale (only for reprints)
  void incrementPrintCount(String saleId) {
    state = state.map((sale) {
      if (sale.id == saleId) {
        return sale.copyWith(printCount: (sale.printCount ?? 0) + 1);
      }
      return sale;
    }).toList();
  }

  /// Get sales for a specific date range
  List<Sale> getSalesInRange(DateTime start, DateTime end) {
    return state.where((sale) {
      return sale.createdAt.isAfter(start) && sale.createdAt.isBefore(end);
    }).toList();
  }

  /// Get sales by payment method
  List<Sale> getSalesByPaymentMethod(String paymentMethod) {
    return state.where((sale) => sale.paymentMethod == paymentMethod).toList();
  }

  /// Get today's sales
  List<Sale> getTodaySales() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getSalesInRange(startOfDay, endOfDay);
  }

  /// Get total revenue for today
  double getTodayRevenue() {
    return getTodaySales().fold(0.0, (sum, sale) => sum + sale.total);
  }

  /// Get total revenue for all time
  double getTotalRevenue() {
    return state.fold(0.0, (sum, sale) => sum + sale.total);
  }

  /// Clear all sales
  void clearAll() {
    state = [];
  }
}

/// Sales provider
final salesProvider = StateNotifierProvider<SalesNotifier, List<Sale>>((ref) {
  return SalesNotifier();
});

/// Today's sales provider
final todaySalesProvider = Provider<List<Sale>>((ref) {
  final sales = ref.watch(salesProvider);
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  return sales.where((sale) {
    return sale.createdAt.isAfter(startOfDay) &&
        sale.createdAt.isBefore(endOfDay);
  }).toList();
});

/// Today's revenue provider
final todayRevenueProvider = Provider<double>((ref) {
  final todaySales = ref.watch(todaySalesProvider);
  return todaySales.fold(0.0, (sum, sale) => sum + sale.total);
});

/// Today's sales count provider
final todaySalesCountProvider = Provider<int>((ref) {
  final todaySales = ref.watch(todaySalesProvider);
  return todaySales.length;
});

/// Average sale value for today
final averageSaleValueProvider = Provider<double>((ref) {
  final todaySales = ref.watch(todaySalesProvider);
  final todayRevenue = ref.watch(todayRevenueProvider);

  if (todaySales.isEmpty) return 0.0;
  return todayRevenue / todaySales.length;
});

/// Total revenue provider
final totalRevenueProvider = Provider<double>((ref) {
  final sales = ref.watch(salesProvider);
  return sales.fold(0.0, (sum, sale) => sum + sale.total);
});

/// Sales count provider
final salesCountProvider = Provider<int>((ref) {
  return ref.watch(salesProvider).length;
});

/// Date range filter provider
final dateRangeProvider = StateProvider<SalesDateRange?>((ref) => null);

class SalesDateRange {
  final DateTime start;
  final DateTime end;

  SalesDateRange(this.start, this.end);
}

/// Filtered sales provider
final filteredSalesProvider = Provider<List<Sale>>((ref) {
  final sales = ref.watch(salesProvider);
  final dateRange = ref.watch(dateRangeProvider);

  if (dateRange == null) return sales;

  return sales.where((sale) {
    return sale.createdAt.isAfter(dateRange.start) &&
        sale.createdAt.isBefore(dateRange.end);
  }).toList();
});
