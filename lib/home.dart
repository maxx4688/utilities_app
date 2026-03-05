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
  String selectedCountry = 'India';
  String? selectedState;
  bool loadState = false;
  bool loadCity = false;

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
    try {
      setState(() {
        loadState = true;
      });

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
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        loadState = false;
      });
    }
  }

  //https://countriesnow.space/api/v0.1/countries/state/cities/q?country=India&state=$state
  // For the cities,

  //DropdownButtonFormField Use this for the drop down to show the countries and the states also the cities

  Future getCities() async {
    try {
      setState(() {
        loadCity = true;
      });
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
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        loadCity = false;
      });
    }
  }

  @override
  initState() {
    super.initState();
    getCountry();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: Center(
        child: loading
            ? CircularProgressIndicator(color: back, strokeCap: StrokeCap.round)
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: DropdownButtonFormField(
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: back),
                      dropdownColor: blue,
                      iconSize: 24,
                      isExpanded: true,
                      style: TextStyle(
                        color: back,
                        fontFamily: 'outfit',
                        fontVariations: [FontVariation('wght', 500)],
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: back.withAlpha(30),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: back.withAlpha(30)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: back.withAlpha(30)),
                        ),
                      ),
                      value: selectedCountry,
                      items: country
                          .map(
                            (e) => DropdownMenuItem(
                              value: e['country'],
                              child: Text(e['country']),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {

                          selectedCountry = value as String;
                        });
                        getStates();
                      },
                    ),
                  ),
                  SizedBox(height: 20.0),
                  if (states.isNotEmpty)
                    loadState
                        ? CircularProgressIndicator(
                            color: back,
                            strokeCap: StrokeCap.round,
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "States",
                                  style: TextStyle(
                                    color: back,
                                    fontFamily: 'outfit',
                                    fontVariations: [
                                      FontVariation('wght', 500),
                                    ],
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  states.length.toString(),
                                  style: TextStyle(
                                    color: back,
                                    fontFamily: 'outfit',
                                    fontVariations: [
                                      FontVariation('wght', 500),
                                    ],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  if (states.isNotEmpty)
                    loadState
                        ? CircularProgressIndicator(
                            color: back,
                            strokeCap: StrokeCap.round,
                          )
                        : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: DropdownButtonFormField(
                              icon: Icon(Icons.keyboard_arrow_down_rounded, color: back),
                              dropdownColor: blue,
                              iconSize: 24,
                              isExpanded: true,
                              style: TextStyle(
                                color: back,
                                fontFamily: 'outfit',
                                fontVariations: [FontVariation('wght', 500)],
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: back.withAlpha(30),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: back.withAlpha(30)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: back.withAlpha(30)),
                                ),
                              ),
                              value: selectedState,
                              items: states.map((e) => DropdownMenuItem(value: e['name'], child: Text(e['name']))).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedState = value as String;
                                });
                                getCities();
                              },
                            ),
                        ),
                  SizedBox(height: 20.0),
                  if (cities.isNotEmpty)
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 20.0),
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                        decoration: BoxDecoration(
                          color: back.withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                        ),
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
                    ),
                ],
              ),
      ),
    );
  }
}
