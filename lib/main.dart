import 'package:flutter/material.dart';
import 'package:weather/dash.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo', 
        theme: ThemeData(
          fontFamily: 'outfit',
          primarySwatch: Colors.red,
        ),
        home: DashBoardPage(),
      );
  }
}
