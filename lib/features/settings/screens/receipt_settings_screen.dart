import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_buttons.dart';
import '../providers/settings_provider.dart';
import '../../pos/widgets/receipt_preview_dialog.dart';
import '../../cart/models/cart_item_model.dart';
import '../../products/models/product_model.dart';

/// Receipt Settings Screen
class ReceiptSettingsScreen extends ConsumerStatefulWidget {
  const ReceiptSettingsScreen({super.key});

  @override
  ConsumerState<ReceiptSettingsScreen> createState() =>
      _ReceiptSettingsScreenState();
}

class _ReceiptSettingsScreenState extends ConsumerState<ReceiptSettingsScreen> {
  late TextEditingController _storeNameController;
  late TextEditingController _storeAddressController;
  late TextEditingController _storePhoneController;
  late TextEditingController _storeEmailController;
  late TextEditingController _printerAddressController;
  String _selectedPrinterType = 'None';

  final List<String> _printerTypes = [
    'None',
    'USB',
    'Bluetooth',
    'Network',
    'WiFi',
  ];

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _storeNameController = TextEditingController(text: settings.storeName);
    _storeAddressController = TextEditingController(
      text: settings.storeAddress,
    );
    _storePhoneController = TextEditingController(text: settings.storePhone);
    _storeEmailController = TextEditingController(
      text: settings.storeEmail ?? '',
    );
    _printerAddressController = TextEditingController(
      text: settings.printerAddress ?? '',
    );
    _selectedPrinterType = settings.printerType;
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeAddressController.dispose();
    _storePhoneController.dispose();
    _storeEmailController.dispose();
    _printerAddressController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final settingsNotifier = ref.read(settingsProvider.notifier);

    settingsNotifier.updateStoreName(_storeNameController.text);
    settingsNotifier.updateStoreAddress(_storeAddressController.text);
    settingsNotifier.updateStorePhone(_storePhoneController.text);
    settingsNotifier.updateStoreEmail(_storeEmailController.text);
    settingsNotifier.updatePrinterType(_selectedPrinterType);
    settingsNotifier.updatePrinterAddress(_printerAddressController.text);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt settings saved successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showReceiptPreview() {
    final settings = ref.read(settingsProvider);

    // Create sample cart items for preview
    final sampleItems = [
      CartItem(
        id: 'cart1',
        product: Product(
          id: 'sample1',
          name: 'Sample Coffee',
          description: 'Delicious coffee',
          barcode: '123456789',
          price: 3.50,
          quantity: 100,
          category: 'Beverages',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        quantity: 2,
        addedAt: DateTime.now(),
      ),
      CartItem(
        id: 'cart2',
        product: Product(
          id: 'sample2',
          name: 'Sample Sandwich',
          description: 'Fresh sandwich',
          barcode: '987654321',
          price: 8.50,
          quantity: 50,
          category: 'Food',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        quantity: 1,
        addedAt: DateTime.now(),
      ),
      CartItem(
        id: 'cart3',
        product: Product(
          id: 'sample3',
          name: 'Sample Juice',
          description: 'Refreshing juice',
          barcode: '456789123',
          price: 4.00,
          quantity: 75,
          category: 'Beverages',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        quantity: 3,
        addedAt: DateTime.now(),
      ),
    ];

    // Calculate totals
    final subtotal = sampleItems.fold<double>(
      0.0,
      (sum, item) => sum + item.subtotal,
    );
    final discount = subtotal * 0.10; // 10% discount for preview
    final tax = (subtotal - discount) * settings.taxRate;
    final total = subtotal - discount + tax;

    showDialog(
      context: context,
      builder: (context) => ReceiptPreviewDialog(
        items: sampleItems,
        subtotal: subtotal,
        discount: discount,
        tax: tax,
        total: total,
        paymentMethod: 'Cash',
        cashierName: 'Sample Cashier',
        customerName: null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.preview),
            tooltip: 'Preview Receipt',
            onPressed: _showReceiptPreview,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Information Section
            _buildSectionHeader(
              'Store Information',
              'Details that appear on receipts',
              Icons.store,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Store Name',
              controller: _storeNameController,
              hint: 'Enter store name',
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Store Address',
              controller: _storeAddressController,
              hint: 'Enter store address',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Store Phone',
              controller: _storePhoneController,
              hint: '+1 (555) 123-4567',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Store Email',
              controller: _storeEmailController,
              hint: 'store@example.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 32),

            // Printer Configuration Section
            _buildSectionHeader(
              'Printer Configuration',
              'Setup your printer connection',
              Icons.print,
            ),
            const SizedBox(height: 16),

            // Printer Type Dropdown
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPrinterType,
                  isExpanded: true,
                  hint: const Text('Select Printer Type'),
                  items: _printerTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Row(
                        children: [
                          Icon(
                            _getPrinterIcon(type),
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(type),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedPrinterType = newValue;
                      });
                    }
                  },
                ),
              ),
            ),

            if (_selectedPrinterType != 'None') ...[
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Printer Address',
                controller: _printerAddressController,
                hint: _getPrinterAddressHint(),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement printer connection test
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Testing printer connection...'),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Test Connection'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
            const SizedBox(height: 32),

            // Quick Printer Settings Section
            _buildSectionHeader(
              'Quick Printer Settings',
              'Automatic printing options',
              Icons.print,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto Print Receipt'),
              subtitle: const Text('Automatically print receipt after sale'),
              value: settings.autoPrintReceipt,
              onChanged: (_) {
                ref.read(settingsProvider.notifier).toggleAutoPrintReceipt();
              },
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.primary,
            ),
            const Divider(height: 32),

            // Barcode Scanner Settings Section
            _buildSectionHeader(
              'Barcode Scanner',
              'Scanner configuration',
              Icons.qr_code_scanner,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Barcode Scanner'),
              subtitle: const Text('Allow scanning barcodes for products'),
              value: settings.enableBarcodeScanner,
              onChanged: (_) {
                ref.read(settingsProvider.notifier).toggleBarcodeScanner();
              },
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.primary,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Auto-fill Product Details'),
              subtitle: const Text(
                'Automatically fill product info after scanning',
              ),
              value: settings.autofillProductDetails,
              onChanged: settings.enableBarcodeScanner
                  ? (_) {
                      ref
                          .read(settingsProvider.notifier)
                          .toggleAutofillProductDetails();
                    }
                  : null,
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.primary,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Beep Sound on Scan'),
              subtitle: const Text('Play sound when barcode is scanned'),
              value: settings.enableBeepSound,
              onChanged: settings.enableBarcodeScanner
                  ? (_) {
                      ref.read(settingsProvider.notifier).toggleBeepSound();
                    }
                  : null,
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.primary,
            ),
            const Divider(height: 32),

            // Receipt Layout Section
            _buildSectionHeader(
              'Receipt Layout',
              'Customize receipt appearance',
              Icons.article,
            ),
            const SizedBox(height: 16),

            // Receipt preview card
            Card(
              elevation: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Store Name
                    Text(
                      _storeNameController.text.isEmpty
                          ? 'Store Name'
                          : _storeNameController.text,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Store Address
                    Text(
                      _storeAddressController.text.isEmpty
                          ? 'Store Address'
                          : _storeAddressController.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),

                    // Store Contact Info
                    if (_storePhoneController.text.isNotEmpty ||
                        _storeEmailController.text.isNotEmpty) ...[
                      Text(
                        [
                          if (_storePhoneController.text.isNotEmpty)
                            'Tel: ${_storePhoneController.text}',
                          if (_storeEmailController.text.isNotEmpty)
                            _storeEmailController.text,
                        ].join(' | '),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Separator
                    const Divider(thickness: 2),
                    const SizedBox(height: 12),

                    // Receipt Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Receipt #12345',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Cashier: Sample User',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Items Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          flex: 3,
                          child: Text(
                            'Item',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 50,
                          child: Text(
                            'Qty',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(
                          width: 60,
                          child: Text(
                            'Price',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 70,
                          child: Text(
                            'Total',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),

                    // Sample Items
                    _buildReceiptItem('Espresso Coffee', 2, 3.50, 7.00),
                    _buildReceiptItem('Club Sandwich', 1, 8.50, 8.50),
                    _buildReceiptItem('Orange Juice', 2, 4.00, 8.00),

                    const SizedBox(height: 12),
                    const Divider(thickness: 1),
                    const SizedBox(height: 12),

                    // Totals
                    _buildReceiptTotal('Subtotal', 'LKR 23.50'),
                    const SizedBox(height: 4),
                    _buildReceiptTotal('Discount (10%)', '- LKR 2.35'),
                    const SizedBox(height: 4),
                    _buildReceiptTotal(
                      'Tax (${(settings.taxRate * 100).toStringAsFixed(1)}%)',
                      'LKR ${(21.15 * settings.taxRate).toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 8),
                    const Divider(thickness: 2),
                    const SizedBox(height: 8),
                    _buildReceiptTotal(
                      'TOTAL',
                      'LKR ${(21.15 + (21.15 * settings.taxRate)).toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Payment Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payment Method:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        const Text(
                          'Cash',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Footer
                    const Divider(),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'Thank you for your purchase!',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        'Visit us again soon',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (settings.enableBarcodeScanner) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '||||  ||||  ||||  ||||',
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          'Receipt #12345',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            PrimaryButton(
              text: 'Save Settings',
              onPressed: _saveSettings,
              width: double.infinity,
              icon: Icons.save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptItem(String name, int qty, double price, double total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Item name
          Expanded(
            flex: 3,
            child: Text(name, style: const TextStyle(fontSize: 12)),
          ),
          // Quantity
          SizedBox(
            width: 50,
            child: Center(
              child: Text('$qty', style: const TextStyle(fontSize: 12)),
            ),
          ),
          // Price
          SizedBox(
            width: 60,
            child: Text(
              price.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          // Total
          SizedBox(
            width: 70,
            child: Text(
              total.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptTotal(
    String label,
    String amount, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 15 : 12,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.black : Colors.grey[700],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 16 : 12,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? Colors.black : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPrinterIcon(String type) {
    switch (type) {
      case 'USB':
        return Icons.usb;
      case 'Bluetooth':
        return Icons.bluetooth;
      case 'Network':
        return Icons.network_wifi;
      case 'WiFi':
        return Icons.wifi;
      default:
        return Icons.print_disabled;
    }
  }

  String _getPrinterAddressHint() {
    switch (_selectedPrinterType) {
      case 'USB':
        return 'e.g., /dev/usb/lp0';
      case 'Bluetooth':
        return 'e.g., 00:11:22:33:44:55';
      case 'Network':
      case 'WiFi':
        return 'e.g., 192.168.1.100';
      default:
        return 'Enter printer address';
    }
  }
}
