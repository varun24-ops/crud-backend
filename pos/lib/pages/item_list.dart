import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventory/services/create/itemDb.dart';
import 'package:inventory/pages/editItemPage.dart';

class ItemList extends StatelessWidget {
  const ItemList({super.key});

  @override
  Widget build(BuildContext context) {
    final ItemService _itemService = ItemService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Items',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _itemService.getItemsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!.docs;

          if (items.isEmpty) {
            return const Center(child: Text('No Items Available'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final data = item.data() as Map<String, dynamic>;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: data['imagePath'] != null && data['imagePath'] != ''
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(data['imagePath']),
                          fit: BoxFit.cover,
                        ),
                      )
                          : const Icon(
                        Icons.shopping_bag,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? '',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${data['price'] ?? '0'}',
                            style: const TextStyle(
                                fontSize: 15, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditItemPage(
                                  itemId: item.id,
                                  currentName: data['name'] ?? '',
                                  currentPrice: data['price'] ?? '',
                                  currentImageUrl: data['imagePath'] ?? '',
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            bool confirm = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirm Delete'),
                                content: const Text('Are you sure you want to delete this item?'),
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

                            if (confirm) {
                              await _itemService.deleteItem(item.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Item deleted successfully")),
                              );
                            }
                          },
                        ),

                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
