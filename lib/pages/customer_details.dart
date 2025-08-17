import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerDetails extends StatelessWidget {
  const CustomerDetails({super.key});

  @override
  Widget build(BuildContext context) {
    final customerId = ModalRoute.of(context)!.settings.arguments as String;

    final customerRef =
    FirebaseFirestore.instance.collection('Customers').doc(customerId);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Details"),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Customer Info
            StreamBuilder<DocumentSnapshot>(
              stream: customerRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.data!.exists) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("Customer not found"),
                  );
                }

                var data = snapshot.data!.data() as Map<String, dynamic>;

                String name = data['name'] ?? "No Name";
                String phone = data['phone'] ?? "";

                // 🔹 Extract purchases map
                Map<String, dynamic> itemsMap =
                Map<String, dynamic>.from(data['items'] ?? {});

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(
                        name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(phone),
                    ),

                    const Divider(thickness: 1),

                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Purchase History",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),

                    if (itemsMap.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text("No purchases found"),
                      )
                    else
                      ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: itemsMap.entries.map((entry) {
                          final date = entry.key; // "dd-MM-yyyy"
                          final itemsForDate =
                          List<Map<String, dynamic>>.from(entry.value);

                          // compute total
                          double total = itemsForDate.fold(
                              0,
                                  (sum, it) =>
                              sum + (it['line_total'] ?? 0).toDouble());

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Purchase on $date",
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text("Total: ₹$total",
                                      style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.black87)),
                                  const Divider(),

                                  // Product List
                                  ...itemsForDate.map((map) {
                                    return ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(map['product_name'] ?? '',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      subtitle: Text(
                                        "Qty: ${map['Quantity'] ?? 0}  •  "
                                            "Price: ₹${map['price'] ?? 0}  •  "
                                            "Line Total: ₹${map['line_total'] ?? 0}",
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
