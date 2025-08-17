import 'package:flutter/material.dart';
import 'package:inventory/services/create/customerDb.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// New Customer dialog
void NewCustomer(BuildContext context) {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        actions: [
          SizedBox(height: 20),
          Row(
            children: [
              Text(
                'New Customer Detail',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 10),
              Icon(Icons.arrow_forward),
            ],
          ),
          SizedBox(height: 20),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: 'Customer\'s Name',
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            style: TextStyle(fontSize: 15),
          ),
          SizedBox(height: 20),
          TextField(
            controller: phoneController,
            decoration: InputDecoration(
              hintText: 'Phone Number',
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            style: TextStyle(fontSize: 15),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  String name = nameController.text.trim();
                  String phone = phoneController.text.trim();

                  if (name.isEmpty || phone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please fill all fields')),
                    );
                    return;
                  }

                  final customerService = CustomerService();
                  await customerService.createCustomer(name, phone);

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Customer saved successfully')),
                  );
                },
                child: const Text("SAVE"),
              ),
            ],
          ),
        ],
      );
    },
  );
}

// Edit Customer dialog
void editCustomer(BuildContext context, String customerId, String currentName, String currentPhone) {
  final TextEditingController nameController = TextEditingController(text: currentName);
  final TextEditingController phoneController = TextEditingController(text: currentPhone);

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        actions: [
          SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Edit Customer Detail',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 10),
              Icon(Icons.arrow_forward),
            ],
          ),
          SizedBox(height: 20),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: 'Customer\'s Name',
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            style: TextStyle(fontSize: 15),
          ),
          SizedBox(height: 20),
          TextField(
            controller: phoneController,
            decoration: InputDecoration(
              hintText: 'Phone Number',
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            style: TextStyle(fontSize: 15),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  String newName = nameController.text.trim();
                  String newPhone = phoneController.text.trim();

                  if (newName.isEmpty || newPhone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please fill all fields')),
                    );
                    return;
                  }

                  await FirebaseFirestore.instance
                      .collection('Customers')
                      .doc(customerId)
                      .update({
                    'name': newName,
                    'phone': newPhone,
                  });

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Customer updated successfully')),
                  );
                },
                child: const Text("SAVE"),
              ),
            ],
          ),
        ],
      );
    },
  );
}
