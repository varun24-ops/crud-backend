// createbill.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventory/pages/edit_bill_page.dart';
import 'package:inventory/services/create/newbillDb.dart';
import 'package:inventory/services/create/itemDb.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class CreateBill extends StatefulWidget {
  const CreateBill({super.key});

  @override
  State<CreateBill> createState() => _CreateBillState();
}

class _CreateBillState extends State<CreateBill> {
  final billService = FirebaseService();
  final ItemService _itemService = ItemService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Bills',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/newbill'),
            child: const Text('ADD'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: billService.getBill(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No bills found'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(data['customer_name'] ?? 'No Name'),
                  subtitle: Text(data['phone_number'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit Button
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditBillPage(
                                docId: doc.id,
                              ),
                            ),
                          );
                        },
                      ),
                      // Delete Button
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          bool confirm = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm Delete'),
                              content: const Text('Are you sure you want to delete this bill?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('No'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Yes'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await billService.deleteBill(doc.id);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Bill deleted successfully')),
                              );
                            }
                          }
                        },
                      ),
                      // PDF Icon
                      IconButton(
                        tooltip: 'View PDF',
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.green),
                        onPressed: () async {
                          await generateAndOpenPdf(data);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Generate PDF invoice and open it.
  /// Uses ItemService.getPriceByName(...) to fetch unit prices.
  Future<void> generateAndOpenPdf(Map<String, dynamic> billData) async {
    final pdf = pw.Document();
    List products = billData['product_details'] ?? [];
    double grandTotal = 0.0;

    // Build rows: each row: [product, qty, unitPrice, lineTotal]
    final List<List<String>> tableRows = [];

    for (var p in products) {
      final productName = (p['product_name'] ?? '').toString();
      final qty = (p['Quantity'] is int) ? p['Quantity'] as int : int.tryParse('${p['Quantity'] ?? 0}') ?? 0;

      // fetch unit price from ItemDB (ItemService)
      double unitPrice = 0.0;
      try {
        final priceFromDb = await _itemService.getPriceByName(productName);
        unitPrice = priceFromDb ?? 0.0;
      } catch (_) {
        unitPrice = 0.0;
      }

      final lineTotal = unitPrice * qty;
      grandTotal += lineTotal;

      tableRows.add([
        productName,
        qty.toString(),
        unitPrice.toStringAsFixed(2),
        lineTotal.toStringAsFixed(2),
      ]);
    }

    // Create a MultiPage to allow multiple pages if many rows.
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('Invoice', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                ]),
                pw.Text(
                  // timestamp display if present
                  (billData['timestamp'] is Timestamp)
                      ? (DateTime.fromMillisecondsSinceEpoch((billData['timestamp'] as Timestamp).millisecondsSinceEpoch).toString())
                      : '',
                  style: pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Text('Customer: ${billData['customer_name'] ?? ''}'),
            pw.Text('Phone: ${billData['phone_number'] ?? ''}'),
            pw.SizedBox(height: 20),

            // Table with controlled column widths so it fits A4 width.
            pw.Table.fromTextArray(
              headers: ['Product', 'Qty', 'Unit Price', 'Total'],
              data: tableRows,
              headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              cellStyle: pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.centerLeft,
              columnWidths: {
                0: const pw.FlexColumnWidth(3), // product name gets more space
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
              },
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
              // reduce cell padding to fit more content
              cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            ),

            pw.SizedBox(height: 12),

            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('Grand Total: ${grandTotal.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ]),
            ]),
          ];
        },
      ),
    );

    // Save and open
    try {
      final directory = await getApplicationDocumentsDirectory();
      // sanitize filename
      final customerName = (billData['customer_name'] ?? 'invoice').toString().replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final file = File('${directory.path}/invoice_${customerName}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    }
  }
}
