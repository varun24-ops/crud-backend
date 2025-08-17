import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:inventory/pages/edit_bill_page.dart';
import 'package:inventory/services/create/newbillDb.dart';

class DashBill extends StatefulWidget {
  const DashBill({super.key});

  @override
  State<DashBill> createState() => _DashBillState();
}

class _DashBillState extends State<DashBill> {
  final bill = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Bill Report',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: bill.getBill(),
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
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await bill.deleteBill(doc.id);
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
}
