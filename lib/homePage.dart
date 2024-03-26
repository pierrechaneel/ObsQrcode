import 'package:flutter/material.dart';
import '/scan.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff000000),
        title: const Text(
          "Orange Event RDC",
          style: TextStyle(
            color: Color(0xFFf97300),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Image.asset(
                'assets/scan.webp',
              ),
              flatButton("Scan QR CODE",
                  ScanPage()),
            ],
          ),
        ),
      ),
    );
  }         

  Widget flatButton(String text, Widget widget) {
    return ElevatedButton(
      onPressed: () async {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => widget));
      },
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(const Color(0xFFf97300)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xffffffff),fontWeight: FontWeight.bold),
      ),
    );
  }
}