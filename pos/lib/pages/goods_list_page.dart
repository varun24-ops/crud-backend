import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/goodsDb.dart';
import 'goods_entry_page.dart';

class GoodsListPage extends StatelessWidget {
  const GoodsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = GoodsService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goods Deliveries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GoodsEntryPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: svc.streamDeliveries(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No deliveries yet'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final supplier = (data['supplier'] ?? '').toString();
              final ts = data['date'] as Timestamp?;
              final dateStr = ts == null
                  ? ''
                  : DateFormat('dd-MM-yyyy').format(ts.toDate());
              final total = (data['total_cost'] ?? 0.0) as num;
              final List<dynamic> items = data['items'] ?? [];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: InkWell(
                  onTap: () async {
                    // edit
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GoodsEntryPage(docId: doc.id),
                      ),
                    );
                  },
                  onLongPress: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete delivery?'),
                        content: const Text('This cannot be undone.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel')),
                          ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete')),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await GoodsService().deleteDelivery(doc.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Deleted')),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                supplier,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            Text('₹${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Date: $dateStr'),
                        const Divider(),
                        ...items.map((it) {
                          final m = it as Map<String, dynamic>;
                          final name = (m['name'] ?? '').toString();
                          final qty =
                              int.tryParse('${m['quantity'] ?? 0}') ?? 0;
                          final price = (m['price'] is num)
                              ? (m['price'] as num).toDouble()
                              : double.tryParse('${m['price']}') ?? 0.0;
                          final line =
                          (m['line_total'] is num) ? (m['line_total'] as num).toDouble() : (qty * price);
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(name),
                            subtitle: Text('Qty: $qty  •  Price: ₹${price.toStringAsFixed(2)}'),
                            trailing: Text('₹${line.toStringAsFixed(2)}'),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
