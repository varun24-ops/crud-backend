import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:inventory/services/create/newbillDb.dart';
import 'package:inventory/services/create/itemDb.dart';
import 'package:inventory/services/create/customerDb.dart';

class EditBillPage extends StatefulWidget {
  final String docId;
  const EditBillPage({super.key, required this.docId});

  @override
  State<EditBillPage> createState() => _EditBillPageState();
}

class _EditBillPageState extends State<EditBillPage> {
  final _billService = FirebaseService();
  final _itemService = ItemService();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _loading = true;

  /// rows: { product_name: String, Quantity: int, price: double }
  final List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _loadBill();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBill() async {
    final snap = await FirebaseFirestore.instance
        .collection('bill_report')
        .doc(widget.docId)
        .get();
    final data = snap.data() as Map<String, dynamic>? ?? {};

    _nameCtrl.text = (data['customer_name'] ?? '').toString();
    _phoneCtrl.text = (data['phone_number'] ?? '').toString();

    final List<dynamic> raw = (data['product_details'] ?? []) as List<dynamic>;
    _rows.clear();
    for (final e in raw) {
      final m = Map<String, dynamic>.from(e as Map);
      final name = (m['product_name'] ?? m['name'] ?? '').toString();
      final qty = int.tryParse('${m['Quantity'] ?? m['quantity'] ?? 0}') ?? 0;
      double? price;
      final pRaw = m['price'];
      if (pRaw != null) {
        price = (pRaw is num) ? pRaw.toDouble() : double.tryParse('$pRaw');
      }
      price ??= await _itemService.getPriceByName(name) ?? 0.0;

      _rows.add({
        'product_name': name,
        'Quantity': qty,
        'price': price,
      });
    }

    if (_rows.isEmpty) {
      _rows.add({'product_name': '', 'Quantity': 1, 'price': 0.0});
    }

    if (mounted) setState(() => _loading = false);
  }

  double get _grandTotal {
    return _rows.fold<double>(
      0.0,
          (sum, r) =>
      sum + ((r['price'] ?? 0.0) as double) * ((r['Quantity'] ?? 0) as int),
    );
  }

  Future<void> _setProductBySelection(int index, String name) async {
    final price = await _itemService.getPriceByName(name.trim());
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product not found in ItemDB')),
      );
      return;
    }
    setState(() {
      _rows[index]['product_name'] = name.trim();
      _rows[index]['price'] = price;
    });
  }

  void _removeRow(int index) {
    setState(() {
      _rows.removeAt(index);
      if (_rows.isEmpty) {
        _rows.add({'product_name': '', 'Quantity': 1, 'price': 0.0});
      }
    });
  }

  void _addRow() {
    setState(() {
      _rows.add({'product_name': '', 'Quantity': 1, 'price': 0.0});
    });
  }

  /// 🔥 Save fully replaces bill + customer purchases
  Future<void> _save() async {
    final cleaned = _rows
        .where((r) => (r['product_name'] as String).trim().isNotEmpty)
        .map((r) => {
      'product_name': (r['product_name'] as String).trim(),
      'Quantity': r['Quantity'] is int
          ? r['Quantity']
          : int.tryParse('${r['Quantity']}') ?? 0,
      'price': (r['price'] is num)
          ? (r['price'] as num).toDouble()
          : double.tryParse('${r['price']}') ?? 0.0,
      'line_total': ((r['price'] is num)
          ? (r['price'] as num).toDouble()
          : double.tryParse('${r['price']}') ?? 0.0) *
          ((r['Quantity'] is int)
              ? r['Quantity']
              : int.tryParse('${r['Quantity']}') ?? 0),
    })
        .toList();

    final total = _grandTotal;

    // 1️⃣ Update bill_report fully
    await _billService.updateBill(
      widget.docId,
      _nameCtrl.text.trim(),
      _phoneCtrl.text.trim(),
      cleaned,
      total: total,
    );

    // 2️⃣ Sync with Customer database (new structure)
    final cs = CustomerService();
    final customerName = _nameCtrl.text.trim();
    final phoneNumber = _phoneCtrl.text.trim();

    if (!await cs.checkCustomerExists(customerName)) {
      await cs.createCustomer(customerName, phoneNumber);
    } else {
      await cs.updatePhone(customerName, phoneNumber);
    }

    // ✅ Instead of Purchases/{billId}, group under items[date]
    final today =
    DateFormat('yyyy-MM-dd').format(DateTime.now()); // just date, no time
    final customerRef =
    FirebaseFirestore.instance.collection('Customers').doc(customerName);

    await customerRef.set({
      'items': {
        today: FieldValue.arrayUnion(cleaned), // append products under this date
      }
    }, SetOptions(merge: true));

    if (mounted) Navigator.pop(context, 'updated');
  }


  @override
  Widget build(BuildContext context) {
    final title = _loading ? 'Loading…' : 'Edit Bill';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Save',
            icon: const Icon(Icons.save),
            onPressed: _loading ? null : _save,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        stream: ItemService().getItemsStream(),
        builder: (context, itemSnap) {
          final allNames = (itemSnap.data?.docs ?? [])
              .map((d) => (d['name'] ?? '').toString())
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Products',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),

                // Header row
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 8),
                  color: Colors.grey.shade300,
                  child: Row(
                    children: const [
                      SizedBox(
                          width: 100,
                          child: Text('Product',
                              style:
                              TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(
                          width: 70,
                          child: Text('Qty',
                              textAlign: TextAlign.center,
                              style:
                              TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(
                          width: 90,
                          child: Text('Total',
                              textAlign: TextAlign.center,
                              style:
                              TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(
                          width: 60,
                          child: Text('Actions',
                              textAlign: TextAlign.center,
                              style:
                              TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),

                // Product list
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: _rows.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade300),
                    itemBuilder: (context, index) {
                      final row = _rows[index];
                      final qty = (row['Quantity'] ?? 0) as int;
                      final price = (row['price'] ?? 0.0) is num
                          ? (row['price'] as num).toDouble()
                          : 0.0;
                      final total = price * qty;

                      final qtyCtrl =
                      TextEditingController(text: qty.toString());

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 100,
                              child: Autocomplete<String>(
                                optionsBuilder: (TextEditingValue tev) {
                                  if (tev.text.isEmpty) {
                                    return const Iterable<String>.empty();
                                  }
                                  return allNames.where((o) => o
                                      .toLowerCase()
                                      .contains(tev.text.toLowerCase()));
                                },
                                onSelected: (sel) =>
                                    _setProductBySelection(index, sel),
                                fieldViewBuilder: (context, controller,
                                    focusNode, onEditingComplete) {
                                  final currentName =
                                  (row['product_name'] ?? '')
                                      .toString();
                                  if (controller.text != currentName) {
                                    controller.text = currentName;
                                    controller.selection =
                                        TextSelection.fromPosition(
                                            TextPosition(
                                                offset: controller
                                                    .text.length));
                                  }
                                  return TextField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    textInputAction: TextInputAction.done,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      hintText: 'Product',
                                      border: OutlineInputBorder(),
                                    ),
                                    onEditingComplete: () async {
                                      onEditingComplete();
                                      final typed =
                                      controller.text.trim();
                                      if (typed.isNotEmpty) {
                                        await _setProductBySelection(
                                            index, typed);
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 70,
                              child: TextField(
                                controller: qtyCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                textAlign: TextAlign.center,
                                onChanged: (v) {
                                  final q = int.tryParse(v) ?? 0;
                                  setState(() =>
                                  _rows[index]['Quantity'] = q);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 70,
                              child: Text(
                                '₹${total.toStringAsFixed(2)}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Remove',
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: () => _removeRow(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),
                Text('Grand Total: ₹${_grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _addRow,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
