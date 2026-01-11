import 'package:flutter/material.dart';
import 'package:weather/service.dart';
import 'package:weather/weather_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
/*

String
Int
double
bool
List
Map

*/


class _HomeScreenState extends State<HomeScreen> {
  List<String> cities = ['Patna', 'Delhi', 'Mumbai', 'Chennai', 'Kolkata', 'Jalandhar' , 'Bangalore'];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: ListView.builder(
        itemCount: cities.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.only(left: 16, right: 16, top: 10),
            shadowColor: back,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: back.withAlpha(30)),
            ),
            color: back.withAlpha(30),
            elevation: 0,
            child: ListTile(
              title: Text(
                cities[index].toUpperCase(),
                style: TextStyle(
                  color: back,
                  fontFamily: 'outfit',
                  fontVariations: const [
                    FontVariation('wght', 500),
                  ],
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WeatherPage(city: cities[index]),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
