import 'package:cloud_firestore/cloud_firestore.dart';

class ProductFirebaseService {
  final CollectionReference ProductReport =
  FirebaseFirestore.instance.collection('bill_report');

  // Local list to keep track of products in the current bill
  static List<Map<String, dynamic>> _currentBillProducts = [];

  /// Add product to Firestore
  Future<void> addBill(String productName, String quantity) {
    var productData = {
      "product_name": productName,
      "Quantity": quantity,
      "timestamp": Timestamp.now(),
    };

    // Add to Firestore
    ProductReport.add(productData);

    // Add to local current bill
    addToCurrentBill(productData);
    print("current bill : ${_currentBillProducts}");
    return Future.value();
  }

  /// Delete product by ID
  Future<void> deleteProduct(String id) {
    return ProductReport.doc(id).delete();
  }

  /// Update product
  Future<void> update(String id, String product, String quantity) {
    return ProductReport.doc(id).update({
      "product_name": product,
      "Quantity": quantity,
    });
  }

  /// Get stream of products for UI
  Stream<QuerySnapshot> getProducts() {
    return ProductReport.orderBy("timestamp", descending: false).snapshots();
  }

  /// Get product by document ID
  Future<Map<String, dynamic>?> getProductById(String id) async {
    try {
      DocumentSnapshot doc = await ProductReport.doc(id).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetching product by ID: $e");
      return null;
    }
  }

  /// Add product to local current bill list
  void addToCurrentBill(Map<String, dynamic> product) {
    _currentBillProducts.add(product);
    print(_currentBillProducts);
  }

  /// Get products added to current bill
  List<Map<String, dynamic>> getCurrentBillProducts() {
    return _currentBillProducts;
  }

  /// Clear local current bill list
  void clearCurrentBill() {
    _currentBillProducts.clear();
  }
}
