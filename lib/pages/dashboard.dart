import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late Future<int> customerCount;
  late Future<int> billCount;
  late Future<int> itemCount;

  @override
  void initState() {
    super.initState();
    loadCounts();
  }

  void loadCounts() {
    customerCount = getCollectionCount('Customers');
    billCount = getCollectionCount('bill_report');
    itemCount = getCollectionCount('Items');
  }

  Future<int> getCollectionCount(String collectionName) async {
    final collection = FirebaseFirestore.instance.collection(collectionName);
    final snapshot = await collection.get();
    return snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with Refresh
        Container(
          margin: EdgeInsets.fromLTRB(20, 5, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sales Activity',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    loadCounts(); // reload all counts
                  });
                },
                icon: Image.asset('assets/images/Dashboard/refresh.png'),
              )
            ],
          ),
        ),

        // Customers Button
        Container(
          margin: EdgeInsets.fromLTRB(20, 5, 20, 0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/dash_customer');
            },
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13)),
              minimumSize: const Size(double.infinity, 50),
              alignment: Alignment.centerLeft,
              backgroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 8),
              side: BorderSide(
                color: Colors.blueAccent,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                        margin: EdgeInsets.all(20),
                        child: Image.asset(
                            'assets/images/Dashboard/customer.png')),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<int>(
                          future: customerCount,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Text('Loading...',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.black));
                            } else if (snapshot.hasError) {
                              return Text('Error',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.black));
                            } else {
                              return Text(snapshot.data.toString(),
                                  style: TextStyle(
                                      fontSize: 25, color: Colors.black));
                            }
                          },
                        ),
                        Text('Customers',
                            style: TextStyle(
                                fontSize: 15, color: Colors.black54))
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                      child: Image.asset(
                          'assets/images/Dashboard/right_arrow.png')),
                ),
              ],
            ),
          ),
        ),

        // Bill Reports Button
        Container(
          margin: EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/dash_bill');
            },
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13)),
              minimumSize: const Size(double.infinity, 50),
              alignment: Alignment.centerLeft,
              backgroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 8),
              side: BorderSide(
                color: Colors.blueAccent,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                        margin: EdgeInsets.all(20),
                        child: Image.asset(
                            'assets/images/Dashboard/bill_report.png')),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<int>(
                          future: billCount,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Text('Loading...',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.black));
                            } else if (snapshot.hasError) {
                              return Text('Error',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.black));
                            } else {
                              return Text(snapshot.data.toString(),
                                  style: TextStyle(
                                      fontSize: 25, color: Colors.black));
                            }
                          },
                        ),
                        Text('Bill Reports',
                            style: TextStyle(
                                fontSize: 15, color: Colors.black54))
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                      child: Image.asset(
                          'assets/images/Dashboard/right_arrow.png')),
                ),
              ],
            ),
          ),
        ),

        // Items Button
        Container(
          margin: EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/item_list');
            },
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13)),
              minimumSize: const Size(double.infinity, 50),
              alignment: Alignment.centerLeft,
              backgroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 8),
              side: BorderSide(
                color: Colors.blueAccent,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                        margin: EdgeInsets.all(20),
                        child: Image.asset(
                            'assets/images/Dashboard/itemlist.png')),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<int>(
                          future: itemCount,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Text('Loading...',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.black));
                            } else if (snapshot.hasError) {
                              return Text('Error',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.black));
                            } else {
                              return Text(snapshot.data.toString(),
                                  style: TextStyle(
                                      fontSize: 25, color: Colors.black));
                            }
                          },
                        ),
                        Text('Items',
                            style: TextStyle(
                                fontSize: 15, color: Colors.black54))
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                      child: Image.asset(
                          'assets/images/Dashboard/right_arrow.png')),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
