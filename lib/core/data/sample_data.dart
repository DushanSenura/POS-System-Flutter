import '../../features/products/models/product_model.dart';
import 'package:uuid/uuid.dart';

/// Sample product data for testing
class SampleData {
  static const _uuid = Uuid();

  static List<Product> getProducts() {
    final now = DateTime.now();

    return [
      Product(
        id: _uuid.v4(),
        name: 'Coffee - Espresso',
        description: 'Premium espresso coffee',
        price: 3.50,
        quantity: 100,
        category: 'Beverages',
        barcode: '1234567890',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: _uuid.v4(),
        name: 'Coffee - Latte',
        description: 'Smooth latte with steamed milk',
        price: 4.50,
        quantity: 85,
        category: 'Beverages',
        barcode: '1234567891',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: _uuid.v4(),
        name: 'Croissant',
        description: 'Buttery, flaky croissant',
        price: 3.00,
        quantity: 50,
        category: 'Bakery',
        barcode: '1234567892',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: _uuid.v4(),
        name: 'Sandwich - Club',
        description: 'Classic club sandwich',
        price: 8.50,
        quantity: 30,
        category: 'Food',
        barcode: '1234567893',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: _uuid.v4(),
        name: 'Juice - Orange',
        description: 'Freshly squeezed orange juice',
        price: 4.00,
        quantity: 60,
        category: 'Beverages',
        barcode: '1234567894',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: _uuid.v4(),
        name: 'Muffin - Blueberry',
        description: 'Fresh blueberry muffin',
        price: 2.50,
        quantity: 75,
        category: 'Bakery',
        barcode: '1234567895',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: _uuid.v4(),
        name: 'Salad - Caesar',
        description: 'Classic caesar salad',
        price: 7.50,
        quantity: 40,
        category: 'Food',
        barcode: '1234567896',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: _uuid.v4(),
        name: 'Tea - Green',
        description: 'Organic green tea',
        price: 2.50,
        quantity: 120,
        category: 'Beverages',
        barcode: '1234567897',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: _uuid.v4(),
        name: 'Bagel - Plain',
        description: 'Fresh plain bagel',
        price: 2.00,
        quantity: 90,
        category: 'Bakery',
        barcode: '1234567898',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: _uuid.v4(),
        name: 'Soup - Tomato',
        description: 'Homemade tomato soup',
        price: 5.50,
        quantity: 25,
        category: 'Food',
        barcode: '1234567899',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  static List<String> getCategories() {
    return ['All', 'Beverages', 'Food', 'Bakery', 'Snacks', 'Other'];
  }
}
