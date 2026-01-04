import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/sale_model.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';

/// Receipt generator and printer
class ReceiptService {
  /// Generate PDF receipt
  static Future<pw.Document> generateReceipt(
    Sale sale,
    String storeName,
    String storeAddress,
    String storePhone,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Store header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      storeName,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      storeAddress,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      storePhone,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Sale info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Receipt #:',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    sale.id.substring(0, 8),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Date:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    DateFormatter.formatDateTime(sale.createdAt),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              if (sale.cashierName != null) ...[
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Cashier:',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      sale.cashierName!,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Items
              ...sale.items.map((item) {
                return pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            item.product.name,
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ),
                        pw.Text(
                          CurrencyFormatter.format(item.subtotal),
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      children: [
                        pw.Text(
                          '  ${item.quantity} x ${CurrencyFormatter.format(item.product.price)}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                  ],
                );
              }).toList(),

              pw.Divider(),
              pw.SizedBox(height: 10),

              // Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 11)),
                  pw.Text(
                    CurrencyFormatter.format(sale.subtotal),
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tax:', style: const pw.TextStyle(fontSize: 11)),
                  pw.Text(
                    CurrencyFormatter.format(sale.tax),
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
              if (sale.discount > 0) ...[
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Discount:',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.Text(
                      '- ${CurrencyFormatter.format(sale.discount)}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ],
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL:',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    CurrencyFormatter.format(sale.total),
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Payment:', style: const pw.TextStyle(fontSize: 11)),
                  pw.Text(
                    sale.paymentMethod,
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Footer
              pw.Center(
                child: pw.Text(
                  'Thank you for your purchase!',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  /// Print receipt
  static Future<void> printReceipt(
    BuildContext context,
    Sale sale,
    String storeName,
    String storeAddress,
    String storePhone,
  ) async {
    final pdf = await generateReceipt(
      sale,
      storeName,
      storeAddress,
      storePhone,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Receipt_${sale.id.substring(0, 8)}.pdf',
    );
  }

  /// Share receipt
  static Future<void> shareReceipt(
    Sale sale,
    String storeName,
    String storeAddress,
    String storePhone,
  ) async {
    final pdf = await generateReceipt(
      sale,
      storeName,
      storeAddress,
      storePhone,
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Receipt_${sale.id.substring(0, 8)}.pdf',
    );
  }
}
