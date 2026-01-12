import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:weather/service.dart';
import 'package:http/http.dart' as http;

class PostMan extends StatefulWidget {
  const PostMan({super.key});

  @override
  State<PostMan> createState() => _PostManState();
}

class _PostManState extends State<PostMan> {
  List method = ['GET', 'POST', 'PUT', 'DELETE'];
  String selectedMethod = 'GET';
  int statusCode = 0;
  TextEditingController urlController = TextEditingController();
  String responseText = '';
  bool isLoading = false;

  Future sendRequest(
    String method,
    String url,
    Map<String, String>? headers,
    String? body,
  ) async {
    try {
      setState(() {
        isLoading = true;
      });

      http.Response? response;
      final uri = Uri.parse(url);

      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(uri, body: body, headers: headers);
          break;
      }

      setState(() {
        statusCode = response!.statusCode;

        try {
          final decoded = jsonDecode(response.body);
          const encoder = JsonEncoder.withIndent('  ');
          responseText = encoder.convert(decoded);
        } catch (e) {
          responseText = response.body;
        }
      });
    } catch (e) {
      setState(() {
        responseText = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget responseConsole(String response) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.5,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Scrollbar(
        radius: Radius.circular(25),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Text(
            response,
            style: TextStyle(
              fontFamily: 'monospace',
              color: Colors.greenAccent,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: ListView(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              method.length,
              (index) => CupertinoButton(
                sizeStyle: CupertinoButtonSize.small,
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    selectedMethod = method[index];
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 3),
                  decoration: selectedMethod == method[index]
                      ? BoxDecoration(
                          color: back,
                          borderRadius: BorderRadius.circular(50),
                        )
                      : null,
                  child: Text(
                    method[index],
                    style: TextStyle(
                      color: selectedMethod == method[index]
                          ? navy
                          : back.withAlpha(100),
                      fontSize: 13,
                      fontFamily: 'outfit',
                      fontVariations: [FontVariation('wght', 500)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Divider(color: back.withAlpha(30)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: TextField(
              controller: urlController,
              cursorColor: blue,
              enabled: !isLoading,
              style: TextStyle(
                color: back,
                fontFamily: 'outfit',
                fontVariations: [FontVariation('wght', 500)],
              ),
              decoration: InputDecoration(
                hintText: 'Enter URL',
                hintStyle: TextStyle(
                  color: back.withAlpha(50),
                  fontFamily: 'outfit',
                  fontVariations: [FontVariation('wght', 500)],
                ),
                suffixIcon: urlController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          setState(() {
                            urlController.clear();
                          });
                        },
                        child: Icon(Icons.close, color: red),
                      )
                    : null,
                border: InputBorder.none,
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: blue),
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: back.withAlpha(30)),
                  borderRadius: BorderRadius.circular(10),
                ),
                errorBorder: InputBorder.none,
                disabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: red),
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          ExpansionTile(
            iconColor: blue,
            collapsedIconColor: back,
            title: Text(
              'Headers',
              style: TextStyle(
                color: back,
                fontFamily: 'outfit',
                fontVariations: [FontVariation('wght', 500)],
              ),
            ),
            children: [
              Container(
                margin: const EdgeInsets.all(15),
                height: 400,
                decoration: BoxDecoration(
                  color: back.withAlpha(20),
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              ],
          ),
          if (statusCode != 0)
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text(
                statusCode.toString(),
                style: TextStyle(
                  color: back,
                  fontSize: 40,
                  fontFamily: 'outfit',
                  fontVariations: [FontVariation('wght', 900)],
                ),
              ),
            ),

          if (responseText.isNotEmpty) responseConsole(responseText),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: CupertinoButton(
          color: back.withAlpha(50),
          onPressed: isLoading
              ? null
              : () {
                  sendRequest(selectedMethod, urlController.text, null, null);
                  setState(() {
                    responseText = '';
                    statusCode = 0;
                  });
                },
          sizeStyle: CupertinoButtonSize.medium,
          child: Text(
            isLoading ? 'LOADING...' : 'HIT REQUEST',
            style: TextStyle(
              color: back,
              fontFamily: 'outfit',
              fontVariations: [FontVariation('wght', 500)],
            ),
          ),
        ),
      ),
    );
  }
}
