import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:weather/home.dart';
import 'package:weather/rejection.dart';
import 'package:weather/service.dart';

class DashBoardPage extends StatefulWidget {
  const DashBoardPage({super.key});

  @override
  State<DashBoardPage> createState() => _DashBoardPageState();
}

class _DashBoardPageState extends State<DashBoardPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        backgroundColor: navy,
        title: Text(
          'Hi ashish.',
          style: TextStyle(
            color: back,
            fontFamily: 'outfit',
            fontVariations: [FontVariation('wght', 700)],
          ),
        ),
      ),
      body: Center(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          children: [
            HomeScreen(),
            RejectionPage(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  _pageController.animateToPage(index, duration: Duration(milliseconds: 500), curve: Curves.easeInOutCirc);
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: back,
                unselectedItemColor: back.withAlpha(70),
                selectedFontSize: 0,
                unselectedFontSize: 0,
                items: [
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: EdgeInsets.all(8),
                      decoration: _selectedIndex == 0
                          ? BoxDecoration(
                              color: back.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            )
                          : null,
                      child: Icon(Icons.home),
                    ),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: EdgeInsets.all(8),
                      decoration: _selectedIndex == 1
                          ? BoxDecoration(
                              color: back.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            )
                          : null,
                      child: Icon(Icons.search),
                    ),
                    label: '',
                  ),
                  // BottomNavigationBarItem(
                  //   icon: Icon(Icons.map),
                  //   label: '',
                  // ),
                  // BottomNavigationBarItem(
                  //   icon: Icon(Icons.person),
                  //   label: '',
                  // ),
                ],
              ),
            )
    );
  }
}
