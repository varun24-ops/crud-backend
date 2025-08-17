import 'package:cloud_firestore/cloud_firestore.dart';

class ItemService {
  final _db = FirebaseFirestore.instance;

  Future<void> addItem(String name, String price, String imagePath) async {
    await _db.collection('Items').add({
      'name': name,
      'price': price,
      'imagePath': imagePath,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateItem(String docId, String name, String price, String imagePath) async {
    await _db.collection('Items').doc(docId).update({
      'name': name,
      'price': price,
      'imagePath': imagePath,
    });
  }

  Future<void> deleteItem(String docId) async {
    await _db.collection('Items').doc(docId).delete();
  }

  Stream<QuerySnapshot> getItemsStream() {
    return _db.collection('Items').orderBy('createdAt', descending: true).snapshots();
  }

  Future<double?> getPriceByName(String name) async {
    final query = await _db.collection('Items').where('name', isEqualTo: name).limit(1).get();
    if (query.docs.isNotEmpty) {
      return double.tryParse(query.docs.first['price'].toString());
    }
    return null;
  }
}
