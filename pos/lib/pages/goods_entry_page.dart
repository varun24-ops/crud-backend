import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:inventory/services/create/itemDb.dart';
import '../services/goodsDb.dart';

class GoodsEntryPage extends StatefulWidget {
  final String? docId; // null = create, not null = edit
  const GoodsEntryPage({super.key, this.docId});

  @override
  State<GoodsEntryPage> createState() => _GoodsEntryPageState();
}

class _GoodsEntryPageState extends State<GoodsEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _svc = GoodsService();

  final TextEditingController _supplierCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  final List<Map<String, dynamic>> _items = [];
  final _itemService = ItemService();
  List<String> _itemNames = [];
  Map<String, dynamic> _itemMap = {}; // {name: {price, imagePath,...}}


  // temp inputs for add-row
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();

  bool _loading = false;
  bool _loadingDoc = true;

  @override
  void initState() {
    super.initState();
    _itemService.getItemsStream().listen((snapshot) {
      List<String> names = [];
      Map<String, dynamic> tempMap = {};
      for (var doc in snapshot.docs) {
        names.add(doc['name']);
        tempMap[doc['name']] = {
          "price": doc['price'],
          "imagePath": doc['imagePath'],
        };
      }
      setState(() {
        _itemNames = names;
        _itemMap = tempMap;
      });
    });

    _loadIfEditing();
  }

  Future<void> _loadIfEditing() async {
    if (widget.docId == null) {
      setState(() => _loadingDoc = false);
      return;
    }
    final snap = await _svc.getDelivery(widget.docId!);
    final data = snap.data() ?? {};
    _supplierCtrl.text = (data['supplier'] ?? '').toString();
    _notesCtrl.text = (data['notes'] ?? '').toString();

    final ts = data['date'] as Timestamp?;
    if (ts != null) _selectedDate = ts.toDate();

    final List<dynamic> raw = (data['items'] ?? []) as List<dynamic>;
    _items.clear();
    for (final e in raw) {
      final m = Map<String, dynamic>.from(e as Map);
      final name = (m['name'] ?? '').toString();
      final qty = int.tryParse('${m['quantity'] ?? 0}') ?? 0;
      final price = (m['price'] is num)
          ? (m['price'] as num).toDouble()
          : double.tryParse('${m['price']}') ?? 0.0;
      _items.add({
        'name': name,
        'quantity': qty,
        'price': price,
        'line_total': price * qty,
      });
    }
    setState(() => _loadingDoc = false);
  }

  double get _totalCost {
    return _items.fold<double>(
      0.0,
          (sum, it) => sum + ((it['line_total'] ?? 0.0) as double),
    );
  }

  void _addRow() {
    final name = _nameCtrl.text.trim();
    final qty = int.tryParse(_qtyCtrl.text.trim());
    final price = double.tryParse(_priceCtrl.text.trim());

    if (name.isEmpty || qty == null || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter item, qty and price')),
      );
      return;
    }

    setState(() {
      _items.add({
        'name': name,
        'quantity': qty,
        'price': price,
        'line_total': qty * price,
      });
      _nameCtrl.clear();
      _qtyCtrl.clear();
      _priceCtrl.clear();
    });
  }

  void _removeRow(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _selectedDate,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item')),
      );
      return;
    }

    setState(() => _loading = true);

    final cleaned = _items
        .where((e) => (e['name'] as String).trim().isNotEmpty)
        .map((e) => {
      'name': (e['name'] as String).trim(),
      'quantity': e['quantity'] is int
          ? e['quantity']
          : int.tryParse('${e['quantity']}') ?? 0,
      'price': (e['price'] is num)
          ? (e['price'] as num).toDouble()
          : double.tryParse('${e['price']}') ?? 0.0,
      'line_total': (e['line_total'] is num)
          ? (e['line_total'] as num).toDouble()
          : 0.0,
    })
        .toList();

    final ts = Timestamp.fromDate(
      DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
    );

    try {
      if (widget.docId == null) {
        await _svc.addDelivery(
          supplier: _supplierCtrl.text.trim(),
          date: ts,
          items: cleaned,
          totalCost: _totalCost,
          notes: _notesCtrl.text.trim(),
        );
      } else {
        await _svc.updateDelivery(
          docId: widget.docId!,
          supplier: _supplierCtrl.text.trim(),
          date: ts,
          items: cleaned,
          totalCost: _totalCost,
          notes: _notesCtrl.text.trim(),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved successfully')),
        );
        Navigator.pop(context, 'saved');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _supplierCtrl.dispose();
    _notesCtrl.dispose();
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.docId == null ? 'New Goods Delivery' : 'Edit Delivery';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: _loading ? null : _save,
            icon: const Icon(Icons.save),
            tooltip: 'Save',
          ),
        ],
      ),
      body: _loadingDoc
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _supplierCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Supplier',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Date',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_month),
                            onPressed: _pickDate,
                          ),
                        ),
                        controller: TextEditingController(
                          text:
                          DateFormat('dd-MM-yyyy').format(_selectedDate),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _notesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Add item row
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<String>.empty();
                          }
                          return _itemNames.where((item) =>
                              item.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (val) {
                          _nameCtrl.text = val;
                          if (_itemMap.containsKey(val)) {
                            _priceCtrl.text = _itemMap[val]["price"].toString();
                          }
                        },
                        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                          _nameCtrl.text = controller.text;
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              hintText: 'Item name',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onEditingComplete: onEditingComplete,
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _qtyCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                          hintText: 'Qty',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _priceCtrl,
                        keyboardType:
                        const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          hintText: 'Price',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _addRow,
                      icon: const Icon(Icons.add),
                      tooltip: 'Add item',
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Items table
                if (_items.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          color: Colors.grey.shade200,
                          child: Row(
                            children: const [
                              Expanded(flex: 4, child: Text('Item')),
                              Expanded(flex: 2, child: Text('Qty', textAlign: TextAlign.center)),
                              Expanded(flex: 3, child: Text('Price', textAlign: TextAlign.center)),
                              Expanded(flex: 3, child: Text('Line Total', textAlign: TextAlign.center)),
                              SizedBox(width: 40, child: Text('')),
                            ],
                          ),
                        ),
                        ..._items.asMap().entries.map((e) {
                          final i = e.key;
                          final it = e.value;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(flex: 4, child: Text(it['name'].toString())),
                                Expanded(flex: 2, child: Text(it['quantity'].toString(), textAlign: TextAlign.center)),
                                Expanded(flex: 3, child: Text('₹${(it['price'] as num).toStringAsFixed(2)}', textAlign: TextAlign.center)),
                                Expanded(flex: 3, child: Text('₹${(it['line_total'] as num).toStringAsFixed(2)}', textAlign: TextAlign.center)),
                                IconButton(
                                  onPressed: () => _removeRow(i),
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Total Cost: ₹${_totalCost.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Delivery'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
