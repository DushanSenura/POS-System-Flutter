import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../sales/models/sale_model.dart';
import '../../settings/models/store_settings_model.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';

/// Printer Service
/// Handles thermal/receipt printer integration and communication
class PrinterService {
  /// Print receipt to thermal printer
  static Future<bool> printReceipt({
    required Sale sale,
    required StoreSettings settings,
  }) async {
    try {
      final pdf = await _generateReceiptPDF(sale, settings);

      // Try to find connected printer
      final printer = await _findPrinter(settings.printerType);

      if (printer != null) {
        await Printing.directPrintPdf(
          printer: printer,
          onLayout: (format) => pdf.save(),
        );
        return true;
      } else {
        // Fallback to system print dialog
        await Printing.layoutPdf(
          onLayout: (format) => pdf.save(),
          name: 'Receipt_${sale.id}',
        );
        return true;
      }
    } catch (e) {
      print('Print error: $e');
      return false;
    }
  }

  /// Generate PDF for receipt (thermal printer format)
  static Future<pw.Document> _generateReceiptPDF(
    Sale sale,
    StoreSettings settings,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // 80mm thermal paper
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Store header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      settings.storeName,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      settings.storeAddress,
                      style: const pw.TextStyle(fontSize: 10),
                      textAlign: pw.TextAlign.center,
                    ),
                    if (settings.storePhone.isNotEmpty)
                      pw.Text(
                        settings.storePhone,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    if (settings.storeEmail != null)
                      pw.Text(
                        settings.storeEmail!,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),

              // Receipt details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Receipt #: ${sale.id.substring(0, 8)}'),
                  pw.Text(DateFormatter.formatDateTime(sale.createdAt)),
                ],
              ),
              if (sale.cashierName != null)
                pw.Text('Cashier: ${sale.cashierName}'),
              if (sale.customerName != null)
                pw.Text('Customer: ${sale.customerName}'),

              pw.SizedBox(height: 10),
              pw.Divider(),

              // Items
              pw.Text(
                'ITEMS',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 5),

              ...sale.items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(child: pw.Text(item.product.name)),
                          pw.Text(
                            CurrencyFormatter.format(item.subtotal),
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            '  ${item.quantity} x ${CurrencyFormatter.format(item.product.price)}',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 10),
              pw.Divider(),

              // Summary
              _buildSummaryRow('Subtotal', sale.subtotal),
              if (sale.discount > 0)
                _buildSummaryRow('Discount', -sale.discount),
              _buildSummaryRow(
                'Tax (${(settings.taxRate * 100).toStringAsFixed(0)}%)',
                sale.tax,
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    CurrencyFormatter.format(sale.total),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 10),
              pw.Divider(),

              // Payment method
              pw.Text('Payment: ${sale.paymentMethod}'),

              if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 5),
                pw.Text('Notes: ${sale.notes}'),
              ],

              pw.SizedBox(height: 15),

              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Thank you for your purchase!',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Please come again',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  /// Build summary row helper
  static pw.Widget _buildSummaryRow(String label, double amount) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [pw.Text(label), pw.Text(CurrencyFormatter.format(amount))],
      ),
    );
  }

  /// Find connected printer
  static Future<Printer?> _findPrinter(String printerType) async {
    try {
      if (printerType == 'None') return null;

      final printers = await Printing.listPrinters();

      if (printers.isEmpty) return null;

      // Try to find default printer
      final defaultPrinter = printers.firstWhere(
        (p) => p.isDefault,
        orElse: () => printers.first,
      );

      return defaultPrinter;
    } catch (e) {
      print('Error finding printer: $e');
      return null;
    }
  }

  /// Test printer connection
  static Future<bool> testPrinterConnection(String printerType) async {
    try {
      if (printerType == 'None') return false;

      final printers = await Printing.listPrinters();
      return printers.isNotEmpty;
    } catch (e) {
      print('Printer test failed: $e');
      return false;
    }
  }

  /// Get list of available printers
  static Future<List<Printer>> getAvailablePrinters() async {
    try {
      return await Printing.listPrinters();
    } catch (e) {
      print('Error getting printers: $e');
      return [];
    }
  }

  /// Share receipt as PDF
  static Future<void> shareReceipt({
    required Sale sale,
    required StoreSettings settings,
  }) async {
    try {
      final pdf = await _generateReceiptPDF(sale, settings);
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'receipt_${sale.id}.pdf',
      );
    } catch (e) {
      print('Share error: $e');
    }
  }

  /// Print test page
  static Future<bool> printTestPage(StoreSettings settings) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          build: (context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    settings.storeName,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text('PRINTER TEST'),
                  pw.SizedBox(height: 10),
                  pw.Text('✓ Connection successful'),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Date: ${DateTime.now().toString()}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            );
          },
        ),
      );

      final printer = await _findPrinter(settings.printerType);

      if (printer != null) {
        await Printing.directPrintPdf(
          printer: printer,
          onLayout: (format) => pdf.save(),
        );
        return true;
      } else {
        await Printing.layoutPdf(
          onLayout: (format) => pdf.save(),
          name: 'Printer_Test',
        );
        return true;
      }
    } catch (e) {
      print('Test print error: $e');
      return false;
    }
  }
}
