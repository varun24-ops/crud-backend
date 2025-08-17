import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CustomerService {
  final CollectionReference customersRef =
  FirebaseFirestore.instance.collection('Customers');

  Future<bool> checkCustomerExists(String name) async {
    final doc = await customersRef.doc(name).get();
    return doc.exists;
  }

  Future<void> createCustomer(String name, String phone) async {
    await customersRef.doc(name).set({
      'name': name,
      'phone': phone,
      'items': {}, // 👈 keep items as a map of date -> list
    });
  }

  Future<void> updatePhone(String name, String phone) async {
    await customersRef.doc(name).update({
      'phone': phone,
    });
  }

  /// ✅ Append products grouped by today's date
  Future<void> addItemsGroupedByDate(
      String customerName,
      String phone,
      List<Map<String, dynamic>> newProducts,
      ) async {
    final customerRef = customersRef.doc(customerName);

    final doc = await customerRef.get();
    if (!doc.exists) {
      await createCustomer(customerName, phone);
    } else {
      await updatePhone(customerName, phone);
    }

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Add under today's date
    await customerRef.set({
      'items': {
        today: FieldValue.arrayUnion(newProducts),
      }
    }, SetOptions(merge: true));
  }
}
