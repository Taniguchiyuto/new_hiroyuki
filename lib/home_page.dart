import 'package:flutter/material.dart';
import 'page_one.dart';
import 'page_two.dart';
import 'page_three.dart';
import 'page_four.dart';
import 'page_five.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // ページごとのタイトルリストを用意
  // final List<String> _titles = [
  //   'Home Page',
  //   '教材の管理',
  //   'チャット',
  //   'レポート',
  //   '通知',
  // ];

  final List<Widget> _pages = [
    PageOne(),
    PageTwo(),
    PageThree(),
    PageFour(),
    PageFive(),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: Colors.blue, // 選択されたタブの色
          unselectedItemColor: const Color.fromARGB(255, 58, 67, 73), // 未選択タブの色
          type: BottomNavigationBarType.fixed, // タブの固定
          onTap: (index) {
            setState(() {
              _currentIndex = index; // 選択されたタブに基づいて状態を更新
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'ホーム',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.edit),
              label: '記録する',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'チャット',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart),
              label: 'レポート',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: '通知',
            ),
          ],
        ),
      ),
    );
  }
}
