import 'package:flutter/material.dart';
import 'package:inventory/services/create/productDb.dart';

void showProductEditDialog(BuildContext context, String? id) async {
  TextEditingController productController = TextEditingController();
  TextEditingController quantityController = TextEditingController();

  var products = ProductFirebaseService();

  // If editing (id != null), fetch existing data
  if (id != null) {
    var docData = await products.getProductById(id); // fetch document by ID
    if (docData != null) {
      productController.text = docData['product_name'] ?? '';
      quantityController.text = docData['Quantity']?.toString() ?? '';
    }
  }
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        child: SingleChildScrollView(
          // Moves with keyboard
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Edit Product",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        // delete logic
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),

                // Search field
                TextField(
                  controller: productController,
                  decoration: InputDecoration(
                    hintText: "Search product",
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    // filter logic
                  },
                ),
                SizedBox(height: 12),

                // Quantity field
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Quantity",
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                ),
                SizedBox(height: 16),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (id==null) {
                          products.addBill(productController.text,
                              quantityController.text);
                        }
                        else{
                          products.update(id, productController.text, quantityController.text);
                        }
                        productController.clear();
                        quantityController.clear();
                        Navigator.pop(context);
                      },
                      child: Text("Save"),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      );
    },
  );
}

