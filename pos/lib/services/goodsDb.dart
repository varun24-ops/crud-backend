import 'package:cloud_firestore/cloud_firestore.dart';

class GoodsService {
  final CollectionReference goods =
  FirebaseFirestore.instance.collection('Goods');

  Future<String> addDelivery({
    required String supplier,
    required Timestamp date,
    required List<Map<String, dynamic>> items,
    required double totalCost,
    String? notes,
  }) async {
    final doc = await goods.add({
      'supplier': supplier,
      'date': date,
      'items': items,
      'total_cost': totalCost,
      'notes': notes ?? '',
      'created_at': Timestamp.now(),
      'updated_at': Timestamp.now(),
    });
    return doc.id;
  }

  Future<void> updateDelivery({
    required String docId,
    required String supplier,
    required Timestamp date,
    required List<Map<String, dynamic>> items,
    required double totalCost,
    String? notes,
  }) async {
    await goods.doc(docId).set({
      'supplier': supplier,
      'date': date,
      'items': items,
      'total_cost': totalCost,
      'notes': notes ?? '',
      'updated_at': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteDelivery(String docId) async {
    await goods.doc(docId).delete();
  }

  Stream<QuerySnapshot> streamDeliveries() {
    return goods.orderBy('date', descending: true).snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getDelivery(String docId) {
    return goods.doc(docId).get() as Future<DocumentSnapshot<Map<String, dynamic>>>;
  }
}
