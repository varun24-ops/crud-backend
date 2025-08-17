import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final CollectionReference<Map<String, dynamic>> billReport =
  FirebaseFirestore.instance.collection('bill_report')
      .withConverter<Map<String, dynamic>>(
    fromFirestore: (snap, _) => snap.data() ?? {},
    toFirestore: (data, _) => data,
  );

  Future<void> addBill(
      String customerName,
      String phoneNumber,
      List<Map<String, dynamic>> products, {
        double total = 0.0,
      }) async {
    await billReport.add({
      "customer_name": customerName,
      "phone_number": phoneNumber,
      "product_details": products,
      "total": total, // ✅ store total
      "timestamp": Timestamp.now(),
    });
  }

  Future<void> updateBill(
      String docId,
      String customerName,
      String phoneNumber,
      List<Map<String, dynamic>> products, {
        double total = 0.0,
      }) async {
    await billReport.doc(docId).update({
      "customer_name": customerName,
      "phone_number": phoneNumber,
      "product_details": products,
      "total": total, // ✅ store total
      "timestamp": Timestamp.now(),
    });
  }

  Future<void> deleteBill(String docId) async {
    await billReport.doc(docId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getBill() {
    return billReport.orderBy('timestamp', descending: true).snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getBillById(String docId) {
    return billReport.doc(docId).get(); // ✅ safe
  }
}
