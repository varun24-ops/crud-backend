import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:inventory/services/create/newbillDb.dart'; // FirebaseService (bill_report)
import 'package:inventory/services/create/itemDb.dart'; // ItemService
import 'package:inventory/services/create/customerDb.dart'; // CustomerService

class NewBill extends StatefulWidget {
  const NewBill({super.key});

  @override
  State<NewBill> createState() => _NewBillState();
}

class _NewBillState extends State<NewBill> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  final _billService = FirebaseService(); // your bill_report service
  final _itemService = ItemService(); // your Items service
  final _customerService = CustomerService(); // your Customers service

  final List<Map<String, dynamic>> _products = [];

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  double get _grandTotal {
    return _products.fold<double>(
      0.0,
          (sum, p) => sum + ((p['price'] ?? 0.0) as double) * ((p['Quantity'] ?? 0) as int),
    );
  }

  String _displayText(String input) => input.length <= 12 ? input : '${input.substring(0, 12)}…';

  void _addOrEditProductDialog({int? editIndex}) {
    final productCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final manualPriceCtrl = TextEditingController();
    double? unitPrice;
    String? notFoundMsg;

    if (editIndex != null) {
      final row = _products[editIndex];
      productCtrl.text = (row['product_name'] ?? '').toString();
      qtyCtrl.text = (row['Quantity'] ?? 1).toString();
      unitPrice = (row['price'] ?? 0.0) is num
          ? (row['price'] as num).toDouble()
          : double.tryParse('${row['price']}') ?? 0.0;
      if (unitPrice == 0.0) unitPrice = null;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => StatefulBuilder(builder: (context, setLocal) {
        Future<void> fetchPrice(String name) async {
          notFoundMsg = null;
          unitPrice = null;
          setLocal(() {});
          final price = await _itemService.getPriceByName(name.trim());
          if (price == null) {
            notFoundMsg = 'Product not found in ItemDB. Enter price manually to save.';
          } else {
            unitPrice = price;
          }
          setLocal(() {});
        }

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add / Edit Item',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  StreamBuilder<QuerySnapshot>(
                    stream: _itemService.getItemsStream(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: LinearProgressIndicator(),
                        );
                      }
                      final names = snap.data!.docs
                          .map((d) => (d['name'] ?? '').toString())
                          .where((s) => s.isNotEmpty)
                          .toSet()
                          .toList();

                      return Autocomplete<String>(
                        optionsBuilder: (TextEditingValue tev) {
                          if (tev.text.isEmpty) return const Iterable<String>.empty();
                          return names.where(
                                  (o) => o.toLowerCase().contains(tev.text.toLowerCase()));
                        },
                        onSelected: (sel) async {
                          productCtrl.text = sel;
                          await fetchPrice(sel);
                        },
                        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                          if (controller.text != productCtrl.text) {
                            controller.text = productCtrl.text;
                            controller.selection = TextSelection.fromPosition(
                                TextPosition(offset: controller.text.length));
                          }
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                                hintText: 'Product Name', border: OutlineInputBorder()),
                            onChanged: (_) {
                              if (unitPrice != null || notFoundMsg != null) {
                                unitPrice = null;
                                notFoundMsg = null;
                                setLocal(() {});
                              }
                            },
                            onEditingComplete: () async {
                              onEditingComplete();
                              final typed = controller.text.trim();
                              if (typed.isNotEmpty) await fetchPrice(typed);
                            },
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        hintText: 'Quantity', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),

                  if (unitPrice != null)
                    Text('Unit Price: ₹${unitPrice!.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (unitPrice != null)
                    Text('Line Total: ₹${((int.tryParse(qtyCtrl.text) ?? 1) * unitPrice!).toStringAsFixed(2)}'),

                  if (notFoundMsg != null) ...[
                    const SizedBox(height: 8),
                    Text(notFoundMsg!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: manualPriceCtrl,
                      keyboardType: TextInputType.numberWithOptions(decimal: true), // FIXED
                      decoration: const InputDecoration(
                          hintText: 'Enter unit price (₹)', border: OutlineInputBorder()),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final name = productCtrl.text.trim();
                        final qty = int.tryParse(qtyCtrl.text) ?? 0;

                        if (name.isEmpty || qty <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Enter valid name and qty')));
                          return;
                        }

                        double? finalPrice = unitPrice;
                        if (finalPrice == null && manualPriceCtrl.text.trim().isNotEmpty) {
                          finalPrice = double.tryParse(manualPriceCtrl.text.trim());
                        }

                        if (finalPrice == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Enter price for this product')));
                          return;
                        }

                        final priceFromDb = await _itemService.getPriceByName(name);
                        if (priceFromDb == null) {
                          await _itemService.addItem(name, finalPrice.toString(), '');
                        }

                        final row = {
                          'product_name': name,
                          'Quantity': qty,
                          'price': finalPrice
                        };

                        setState(() {
                          if (editIndex != null) {
                            _products[editIndex] = row;
                          } else {
                            _products.add(row);
                          }
                        });

                        Navigator.pop(context);
                      },
                      child: const Text('Save'),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  void _deleteRow(int index) {
    setState(() {
      _products.removeAt(index);
    });
  }

  Future<void> _saveBill() async {
    final customerName = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (customerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter customer name')));
      return;
    }
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one product')));
      return;
    }

    try {
      final normalizedProducts = _products.map((p) {
        final price = (p['price'] is num)
            ? (p['price'] as num).toDouble()
            : double.tryParse('${p['price']}') ?? 0.0;
        final qty = (p['Quantity'] is int)
            ? p['Quantity'] as int
            : int.tryParse('${p['Quantity']}') ?? 0;
        return {
          'product_name': (p['product_name'] ?? '').toString(),
          'Quantity': qty,
          'price': price,
          'line_total': (price * qty),
        };
      }).toList();

      final grandTotal =
      normalizedProducts.fold<double>(0.0, (s, e) => s + (e['line_total'] as double));

      await _billService.addBill(
          customerName,
          phone,
          normalizedProducts.map((p) => {
            'product_name': p['product_name'],
            'Quantity': p['Quantity'],
            'price': p['price'],
          }).toList());

      final exists = await _customerService.checkCustomerExists(customerName);
      if (!exists) {
        await _customerService.createCustomer(customerName, phone);
      }

      final billDoc = {
        'customer_name': customerName,
        'phone': phone,
        'items': normalizedProducts,
        'total': grandTotal,
        'timestamp': Timestamp.now(),
      };

      final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());;

      await FirebaseFirestore.instance
          .collection('Customers')
          .doc(customerName)
          .set({
        'name': customerName,
        'phone': phone,
        'items': {
          dateKey: FieldValue.arrayUnion(normalizedProducts),
        },
      }, SetOptions(merge: true));


      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Bill saved successfully')));

      setState(() {
        _products.clear();
        nameController.clear();
        phoneController.clear();
      });

      Navigator.pop(context, 'saved');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error saving bill: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar:
      AppBar(title: const Text('New Bill', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    height: 200,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            spreadRadius: 1,
                            blurRadius: 6,
                            offset: Offset(0, 3)) // FIXED removed extra paren
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(children: const [
                          Text('Customer Details',
                              style:
                              TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward)
                        ]),
                        TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                                hintText: "Customer's Name",
                                contentPadding:
                                EdgeInsets.symmetric(vertical: 0, horizontal: 16))),
                        TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                                hintText: 'Phone Number',
                                contentPadding:
                                EdgeInsets.symmetric(vertical: 0, horizontal: 16))),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            spreadRadius: 1,
                            blurRadius: 6,
                            offset: Offset(0, 3)) // FIXED
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Product Details',
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold)),
                              ElevatedButton(
                                  onPressed: () => _addOrEditProductDialog(),
                                  child: const Text('Add Items')),
                            ]),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                          color: Colors.grey.shade300,
                          child: Row(children: const [
                            SizedBox(
                                width: 80,
                                child: Text('Product',
                                    style: TextStyle(fontWeight: FontWeight.bold))),
                            SizedBox(
                                width: 60,
                                child: Text('Qty',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center)),
                            SizedBox(
                                width: 80,
                                child: Text('Total',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center)),
                            SizedBox(
                                width: 60,
                                child: Text('Actions',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center)),
                          ]),
                        ),

                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final p = _products[index];
                            final qty = (p['Quantity'] ?? 0) as int;
                            final price = (p['price'] ?? 0.0) is num
                                ? (p['price'] as num).toDouble()
                                : 0.0;
                            final lineTotal = price * qty;

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 8),
                              decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                          color: Colors.grey.shade300))),
                              child: Row(children: [
                                SizedBox(
                                    width: 60,
                                    child: Text(_displayText(
                                        (p['product_name'] ?? '').toString()))),
                                const SizedBox(width: 4),
                                SizedBox(
                                    width: 50,
                                    child:
                                    Text(qty.toString(), textAlign: TextAlign.center)),
                                const SizedBox(width: 4),
                                SizedBox(
                                    width: 70,
                                    child: Text('₹${lineTotal.toStringAsFixed(2)}',
                                        textAlign: TextAlign.center)),
                                const SizedBox(width: 4),
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                          tooltip: 'Edit',
                                          icon: const Icon(Icons.edit, size: 18),
                                          onPressed: () =>
                                              _addOrEditProductDialog(editIndex: index)),
                                      IconButton(
                                          tooltip: 'Delete',
                                          icon: const Icon(Icons.delete_outline, size: 18),
                                          onPressed: () => _deleteRow(index)),
                                    ]),
                              ]),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    topLeft: Radius.circular(20))),
            child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              Text('Grand Total : ₹${_grandTotal.toStringAsFixed(2)}',
                  style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(elevation: 0),
                      child: const Text('Cancel')),
                  ElevatedButton(onPressed: _saveBill, child: const Text('SAVE')),
                ]),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
