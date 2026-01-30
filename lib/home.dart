import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:weather/service.dart';
import 'package:http/http.dart' as http;
import 'package:weather/weather_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool loading = false;
  List country = [];
  List states = [];
  List cities = [];
  String selectedCountry = 'Select Country';
  String selectedState = 'Select State';

  Future getCountry() async {
    try {
      setState(() {
        loading = true;
      });
      final res = await http.get(
        Uri.parse("https://countriesnow.space/api/v0.1/countries"),
      );

      if (res.statusCode == 200) {
        final response = jsonDecode(res.body);
        setState(() {
          country = response['data'];
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future getStates() async {
    final res = await http.get(
      Uri.parse(
        "https://countriesnow.space/api/v0.1/countries/states/q?country=$selectedCountry",
      ),
    );
    if (res.statusCode == 200) {
      final response = jsonDecode(res.body);
      setState(() {
        states = response['data']['states'];
      });
    }
  }

  //https://countriesnow.space/api/v0.1/countries/state/cities/q?country=India&state=$state
  // For the cities,

  Future getCities() async {
    final res = await http.get(
      Uri.parse(
        "https://countriesnow.space/api/v0.1/countries/state/cities/q?country=$selectedCountry&state=$selectedState",
      ),
    );
    if (res.statusCode == 200) {
      final response = jsonDecode(res.body);
      setState(() {
        cities = response['data'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: Center(
        child: loading
            ? CircularProgressIndicator(color: back, strokeCap: StrokeCap.round)
            : country.isEmpty
            ? CupertinoButton(
                sizeStyle: CupertinoButtonSize.medium,
                color: back.withAlpha(30),
                child: Text(
                  "Get Country",
                  style: TextStyle(
                    fontFamily: 'outfit',
                    fontVariations: [FontVariation('wght', 500)],
                    fontSize: 16,
                    color: back,
                  ),
                ),
                onPressed: () {
                  getCountry();
                },
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedCountry,
                          style: TextStyle(
                            color: back,
                            fontFamily: 'outfit',
                            fontVariations: [FontVariation('wght', 500)],
                            fontSize: 16,
                          ),
                        ),
                        CupertinoButton(
                          sizeStyle: CupertinoButtonSize.medium,
                          color: back.withAlpha(30),
                          onPressed: () {
                            showBottomSheet(
                              context: context,
                              builder: (context) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: back,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: ListView(
                                    shrinkWrap: true,
                                    children: List.generate(country.length, (
                                      index,
                                    ) {
                                      final num = (index + 1).toString();
                                      return ListTile(
                                        title: Text(
                                          country[index]['country'],
                                          style: TextStyle(
                                            color: navy,
                                            fontFamily: 'outfit',
                                            fontVariations: [
                                              FontVariation('wght', 500),
                                            ],
                                            fontSize: 16,
                                          ),
                                        ),
                                        leading: CircleAvatar(
                                          backgroundColor: back.withAlpha(30),
                                          radius: 20,
                                          child: Text(
                                            num,
                                            style: TextStyle(
                                              color: navy,
                                              fontFamily: 'outfit',
                                              fontVariations: [
                                                FontVariation('wght', 800),
                                              ],
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        onTap: () {
                                          setState(() {
                                            selectedCountry =
                                                country[index]['country'];
                                          });
                                          getStates();
                                          Navigator.pop(context);
                                        },
                                      );
                                    }),
                                  ),
                                );
                              },
                            );
                          },
                          child: Text('Change', style: TextStyle(color: back, fontFamily: 'outfit', fontVariations: [FontVariation('wght', 500)], fontSize: 16,),),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.0),
                  if (states.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "States",
                            style: TextStyle(
                              color: back,
                              fontFamily: 'outfit',
                              fontVariations: [FontVariation('wght', 500)],
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            states.length.toString(),
                            style: TextStyle(
                              color: back,
                              fontFamily: 'outfit',
                              fontVariations: [FontVariation('wght', 500)],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (states.isNotEmpty)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 20.0),
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      decoration: BoxDecoration(
                        color: back.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: states.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            minTileHeight: 50,
                            tileColor: selectedState == states[index]['name']
                                ? back.withAlpha(30)
                                : null,
                            onTap: () {
                              getCities();
                              setState(() {
                                selectedState = states[index]['name'];
                              });
                            },
                            title: Text(
                              states[index]['name'],
                              style: TextStyle(
                                color: back,
                                fontFamily: 'outfit',
                                fontVariations: [FontVariation('wght', 500)],
                                fontSize: 16,
                              ),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: back.withAlpha(30),
                              radius: 20,
                              child: Text(
                                states[index]['state_code'],
                                style: TextStyle(
                                  color: back,
                                  fontFamily: 'outfit',
                                  fontVariations: [FontVariation('wght', 800)],
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  SizedBox(height: 20.0),
                  if (cities.isNotEmpty)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 20.0),
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      decoration: BoxDecoration(
                        color: back.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: cities.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            minTileHeight: 50,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      WeatherPage(city: cities[index]),
                                ),
                              );
                            },
                            title: Text(
                              cities[index],
                              style: TextStyle(
                                color: back,
                                fontFamily: 'outfit',
                                fontVariations: [FontVariation('wght', 500)],
                                fontSize: 16,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
