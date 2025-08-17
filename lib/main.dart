import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:inventory/firebase_options.dart';
import 'package:inventory/pages/create.dart';
import 'package:inventory/pages/createbill.dart';
import 'package:inventory/pages/createcustomer.dart';
import 'package:inventory/pages/customer_details.dart';
import 'package:inventory/pages/dash_bill.dart';
import 'package:inventory/pages/dash_customer.dart';
import 'package:inventory/pages/dash_item.dart';
import 'package:inventory/pages/dashboard.dart';
import 'package:inventory/pages/edit_bill_page.dart';
import 'package:inventory/pages/item.dart';
import 'package:inventory/pages/item_list.dart';
import 'package:inventory/pages/newbill.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PV Subramaniam Electricals',
      initialRoute: '/',
      routes: {
        '/createbill': (context) => CreateBill(),
        '/createcustomer': (context) => CreateCustomer(),
        '/newbill': (context) => NewBill(),
        '/dash_customer': (context) => DashCustomer(),
        '/dash_bill': (context) => DashBill(),
        '/dash_item': (context) => DashItem(),
        '/customer_details': (context) => CustomerDetails(),
        '/item': (context) => ItemInputPage(),
        '/item_list': (context) => ItemList(),
        '/edit_bill_page': (context) => EditBillPage(docId: ''),
      },
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text(
            'PV Subramaniam Electricals',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            labelColor: Colors.black,
            indicatorColor: Colors.black,
            unselectedLabelColor: Colors.black54,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 16,
                      width: 16,
                      child: Icon(Icons.dashboard),
                    ),
                    SizedBox(width: 15),
                    Text('Dashboard',),

                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 14,
                      width: 14,
                      child: Icon(Icons.add),
                    ),
                    SizedBox(width: 15),
                    Text('Create'),
                  ],
                ),
              ),
            ],
          ),
        ),
        drawer: Drawer(
          backgroundColor: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.deepPurple),
                child: Center(
                  child: Text(
                    'PV Subramaniam Electricals',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ),
              // Drawer items
              _drawerItem(
                icon: Icons.home,
                text: 'Home',
                context: context,
                onTap: () {
                  Navigator.pop(context); // just close drawer
                },
              ),
              _drawerItem(
                icon: Icons.payment,
                text: 'Payments',
                context: context,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _drawerItem(
                icon: Icons.output_rounded,
                text: 'Items',
                context: context,
                onTap: () {
                  Navigator.pop(context); // close drawer first
                  Future.delayed(const Duration(milliseconds: 100), () {
                    Navigator.pushNamed(context, '/dash_item');// navigate safely
                  });
                },
              ),
              _drawerItem(
                icon: Icons.settings,
                text: 'Settings',
                context: context,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _drawerItem(
                icon: Icons.info,
                text: 'About',
                context: context,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Dashboard(),
            Create(),
          ],
        ),
      ),
    );
  }

  // Helper method for cleaner drawer items
  Widget _drawerItem({
    required IconData icon,
    required String text,
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(text),
      onTap: onTap,
    );
  }
}
