import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:weather/service.dart';

class RejectionPage extends StatefulWidget {
  const RejectionPage({super.key});

  @override
  State<RejectionPage> createState() => _RejectionPageState();
}

class _RejectionPageState extends State<RejectionPage> {
  @override
  void initState() {
    super.initState();
    getDecision();
  }

  bool _isLoading = false;
  String decision = 'Loading..';

  Future getDecision() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final res = await http.get(Uri.parse("https://naas.isalman.dev/no"));

      if (res.statusCode == 200) {
        final response = jsonDecode(res.body);
        setState(() {
          decision = response['reason'];
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: Center(
        child: Center(
          child: _isLoading
              ? CircularProgressIndicator(color: back)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Text(
                        decision,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: back,
                          fontFamily: 'outfit',
                          fontSize: 40,
                          fontVariations: [FontVariation('wght', 600)],
                        ),
                      ),
                    ),
                    SizedBox(height: 20,),
                    CupertinoButton(
                      color: back.withAlpha(30),
                      sizeStyle: CupertinoButtonSize.small,
                      onPressed: () {
                        getDecision();
                      },
                      child: Text(
                        'RETRY',
                        style: TextStyle(
                          color: back,
                          fontFamily: 'outfit',
                          fontVariations: [FontVariation('wght', 400)],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
