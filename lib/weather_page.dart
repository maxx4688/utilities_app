import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:weather/service.dart';

class WeatherPage extends StatefulWidget {
  final String city;
  const WeatherPage({super.key, required this.city});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _cityController = TextEditingController();
  Map<String, dynamic>? _weatherData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cityController.text = widget.city;
    getWeather();
  }

  Future<void> getWeather() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await http.get(
        Uri.parse(
          "$baseUrl/weather?q=${_cityController.text.trim()}&appid=$apiKey&units=metric",
        ),
      );
      final response = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() {
          _weatherData = response;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Icon(
                      Icons.cloud_off_rounded,
                      size: 64,
                      color: Colors.black12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'outfit',
                      fontVariations: const [FontVariation('wght', 400)],
                    ),
                  ),
                  const SizedBox(height: 24),
                  CupertinoButton(
                    onPressed: getWeather,
                    color: navy,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    sizeStyle: CupertinoButtonSize.small,
                    child: const Text(
                      "Retry",
                      style: TextStyle(
                        fontFamily: 'outfit',
                        color: Colors.white,
                        fontVariations: [FontVariation('wght', 700)],
                      ),
                    ),
                  ),
                ],
              ),
            )
          :Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [navy, blue, Colors.white],
                ),
              ),
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: back))
                  : RefreshIndicator(
                      onRefresh: getWeather,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.1,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: CupertinoButton(
                                    padding: EdgeInsets.all(10),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _weatherData!['name'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontFamily: 'outfit',
                                      fontVariations: const [
                                        FontVariation('wght', 300),
                                      ],
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    "${_weatherData!['main']['temp'].toStringAsFixed(0)}°",
                                    style: TextStyle(
                                      fontSize: 100,
                                      fontFamily: 'outfit',
                                      fontVariations: const [
                                        FontVariation('wght', 100),
                                      ],
                                      color: Colors.white,
                                    ),
                                  ),
                                  // Text(
                                  //   "IT'S FUCKING ${_weatherData!['weather'][0]['description']
                                  //       .toString()
                                  //       .toUpperCase()} NOW",
                                  //   style: TextStyle(
                                  //     fontSize: 14,
                                  //     color: Colors.white38,
                                  //     fontFamily: 'outfit',
                                  //     fontVariations: const [
                                  //       FontVariation('wght', 900),
                                  //     ],
                                  //   ),
                                  // ),
                                  Text(
                                    _weatherData!['weather'][0]['description']
                                        .toString()
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white38,
                                      fontFamily: 'outfit',
                                      fontVariations: const [
                                        FontVariation('wght', 900),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "Feels like ${_weatherData!['main']['feels_like'].toStringAsFixed(1)}°C",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'outfit',
                                      color: Colors.white,
                                      fontVariations: const [
                                        FontVariation('wght', 300),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.4,
                                children: [
                                  _buildDetailCard(
                                    icon: Icons.water_drop,
                                    label: "Humidity",
                                    value:
                                        "${_weatherData!['main']['humidity']}%",
                                    color: Colors.blue,
                                  ),
                                  _buildDetailCard(
                                    icon: Icons.compress,
                                    label: "Pressure",
                                    value:
                                        "${_weatherData!['main']['pressure']} hPa",
                                    color: Colors.orange,
                                  ),
                                  _buildDetailCard(
                                    icon: Icons.air,
                                    label: "Wind Speed",
                                    value:
                                        "${_weatherData!['wind']['speed']} m/s",
                                    color: Colors.green,
                                  ),
                                  _buildDetailCard(
                                    icon: Icons.visibility,
                                    label: "Visibility",
                                    value:
                                        "${(_weatherData!['visibility'] / 1000).toStringAsFixed(1)} km",
                                    color: Colors.purple,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              Card(
                                elevation: 4,
                                shadowColor: blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                color: Colors.white10,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildTempRangeItem(
                                        icon: Icons.arrow_upward,
                                        label: "Max",
                                        value:
                                            "${_weatherData!['main']['temp_max'].toStringAsFixed(1)}°C",
                                        color: Colors.red,
                                      ),
                                      _buildTempRangeItem(
                                        icon: Icons.arrow_downward,
                                        label: "Min",
                                        value:
                                            "${_weatherData!['main']['temp_min'].toStringAsFixed(1)}°C",
                                        color: Colors.blue,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Sunrise/Sunset Card
                              Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildSunItem(
                                        icon: Icons.wb_sunny,
                                        label: "Sunrise",
                                        value: _formatTime(
                                          _weatherData!['sys']['sunrise'],
                                        ),
                                        color: Colors.orange,
                                      ),
                                      _buildSunItem(
                                        icon: Icons.wb_twilight,
                                        label: "Sunset",
                                        value: _formatTime(
                                          _weatherData!['sys']['sunset'],
                                        ),
                                        color: Colors.deepOrange,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            color: Colors.red.shade400,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Location",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _buildLocationRow(
                                        "Latitude",
                                        "${_weatherData!['coord']['lat']}°",
                                      ),
                                      _buildLocationRow(
                                        "Longitude",
                                        "${_weatherData!['coord']['lon']}°",
                                      ),
                                      _buildLocationRow(
                                        "Country",
                                        _weatherData!['sys']['country'],
                                      ),
                                      _buildLocationRow(
                                        "Timezone",
                                        "UTC ${(_weatherData!['timezone'] / 3600).toStringAsFixed(0)}",
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white10,
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: navy),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontFamily: 'outfit',
              fontVariations: const [FontVariation('wght', 400)],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontFamily: 'outfit',
              fontVariations: const [FontVariation('wght', 800)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTempRangeItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontFamily: 'outfit',
            fontVariations: const [FontVariation('wght', 400)],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSunItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontFamily: 'outfit',
            fontVariations: const [FontVariation('wght', 800)],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
