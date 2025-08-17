import 'package:flutter/material.dart';
import 'package:inventory/pages/goods_list_page.dart';

class Create extends StatelessWidget {
  const Create({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Let\'s Start',style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold,color: Colors.black54),),

            ],
          ),
        ),
        Container(
          margin: EdgeInsets.fromLTRB(20, 20, 20,0),
          child: ElevatedButton(onPressed: (){
            Navigator.pushNamed(context, '/createbill');
          },
            style: ElevatedButton.styleFrom(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(13)
                ),
                minimumSize: const Size(double.infinity, 50), // optional: make button full width
                alignment: Alignment.centerLeft, // align content to left
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 5,vertical: 8),

                side: BorderSide(
                  color: Colors.blueAccent,
                  width: 1,
                )
            ),


            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(

                  children: [
                    Container(
                        margin: EdgeInsets.all(20),
                        child: SizedBox(width:20,height:20,child: Image.asset('assets/images/Create/edit.png'))),

                    Text('Create New Bill',style: TextStyle(fontSize: 16,color: Colors.black54),)
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(child: Image.asset('assets/images/Dashboard/right_arrow.png')),
                ),
              ],

            ),),
        ),
        Container(
          margin: EdgeInsets.fromLTRB(20, 20, 20,0),
          child: ElevatedButton(onPressed: (){
            Navigator.pushNamed(context, '/createcustomer');
          },
            style: ElevatedButton.styleFrom(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(13)
                ),
                minimumSize: const Size(double.infinity, 50), // optional: make button full width
                alignment: Alignment.centerLeft, // align content to left
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 5,vertical: 8),

                side: BorderSide(
                  color: Colors.blueAccent,
                  width: 1,
                )
            ),


            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(

                  children: [
                    Container(
                        margin: EdgeInsets.all(20),
                        child: SizedBox(width:20,height:20,child: Image.asset('assets/images/Create/customer-service.png'))),

                    Text('Add New Customer',style: TextStyle(fontSize: 16,color: Colors.black54),)
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(child: Image.asset('assets/images/Dashboard/right_arrow.png')),
                ),
              ],

            ),),
        ),
        Container(
          margin: EdgeInsets.fromLTRB(20, 20, 20,0),
          child: ElevatedButton(onPressed: (){
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GoodsListPage(),
                ),
              );
          },
            style: ElevatedButton.styleFrom(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(13)
                ),
                minimumSize: const Size(double.infinity, 50), // optional: make button full width
                alignment: Alignment.centerLeft, // align content to left
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 5,vertical: 8),

                side: BorderSide(
                  color: Colors.blueAccent,
                  width: 1,
                )
            ),


            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(

                  children: [
                    Container(
                        margin: EdgeInsets.all(20),
                        child: SizedBox(width:20,height:20,child: Image.asset('assets/images/Create/goods.png'))),

                    Text('Add New Goods List',style: TextStyle(fontSize: 16,color: Colors.black54),)
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(child: Image.asset('assets/images/Dashboard/right_arrow.png')),
                ),
              ],

            ),),
        ),

      ],
    );
  }
}
