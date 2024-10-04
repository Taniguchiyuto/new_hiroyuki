import 'package:flutter/cupertino.dart'; // CupertinoPickerを使用
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';

class UserInfoInputPage extends StatefulWidget {
  final User? user;
  final String message;

  UserInfoInputPage({required this.user, this.message = ''});

  @override
  _UserInfoInputPageState createState() => _UserInfoInputPageState();
}

class _UserInfoInputPageState extends State<UserInfoInputPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _occupationCotroller = TextEditingController();
  int _selectedAge = 18; // 初期値を18歳に設定
  int _selectedOccupationIndex = 0; // 職業の初期選択肢
  final List<String> _occupations = [
    '高校1年生',
    '高校2年生',
    '高校3年生',
    '浪人生(1浪)',
    '浪人生(2浪)',
    '浪人生(3浪)',
    '浪人生(4浪)'
  ]; //職業の選択肢リスト

  @override
  void initState() {
    super.initState();
    _loadUserInfo(); // 初期化時にFirestoreからデータを取得
  }

  Future<void> _loadUserInfo() async {
    if (widget.user != null) {
      DocumentSnapshot userInfo =
          await _firestore.collection('users').doc(widget.user!.uid).get();

      if (userInfo.exists) {
        setState(() {
          _usernameController.text = userInfo['username'] ?? '';
          _targetController.text = userInfo['target'] ?? '';
          _selectedAge = userInfo['age'] ?? 18; // デフォルト年齢を18に設定
          // occupationのインデックスを設定
          String occupation = userInfo['occupation'] ?? _occupations[0];
          _selectedOccupationIndex = _occupations.indexOf(occupation);
        });
      }
    }
  }

  Future<void> _saveUserInfo() async {
    if (widget.user != null &&
        _usernameController.text.isNotEmpty &&
        _targetController.text.isNotEmpty &&
        _occupationCotroller.text.isNotEmpty) {
      // Firestoreにユーザー情報を保存
      await _firestore.collection('users').doc(widget.user!.uid).set({
        'username': _usernameController.text,
        'target': _targetController.text,
        'email': widget.user!.email,
        'occupation': _occupations[_selectedOccupationIndex], // 選択された職業を保存
        'age': _selectedAge, // 選択された年齢を保存
        'studyRank': "A",
        'lifeRank': "A",
        'gradeRank': "A",
        'studySentence': "A",
        'lifeSentence': "A",
        'gradeSentence': "A"
      });

      // 保存後、ホームページに遷移
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      // フィールドが空の場合はエラーメッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('全てのフィールドを入力してください')),
      );
    }
  }

  void _showAgePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          child: CupertinoPicker(
            itemExtent: 32.0,
            onSelectedItemChanged: (int value) {
              setState(() {
                _selectedAge = value + 1; // 年齢は1歳からスタート
              });
            },
            children: List<Widget>.generate(100, (int index) {
              return Center(
                child: Text('${index + 1} 歳'), // 1歳から100歳までの年齢を表示
              );
            }),
          ),
        );
      },
    );
  }

  void _showOccupationPicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          child: CupertinoPicker(
            itemExtent: 32.0,
            onSelectedItemChanged: (int value) {
              setState(() {
                _selectedOccupationIndex = value; // 選択された職業をインデックスに保存
              });
            },
            children: _occupations.map((String occupation) {
              return Center(
                child: Text(occupation), // 職業リストの表示
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ユーザー情報入力")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.asset('assets/images/hiroyuki.png'),
            SizedBox(height: 20),
            if (widget.message.isNotEmpty) ...[
              Text(
                widget.message,
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
              SizedBox(height: 10),
            ],
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'ユーザー名'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _targetController,
              decoration: InputDecoration(labelText: '目標'),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: _showAgePicker, // タップ時に年齢選択ピッカーを表示
              child: AbsorbPointer(
                // TextFieldがタップされても反応しないようにする
                child: TextField(
                  controller: TextEditingController(
                    text: '$_selectedAge 歳', // 選択された年齢を表示
                  ),
                  decoration: InputDecoration(labelText: '年齢'),
                ),
              ),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: _showOccupationPicker, // タップ時に職業選択ピッカーを表示
              child: AbsorbPointer(
                child: TextField(
                  controller: TextEditingController(
                    text: _occupations[_selectedOccupationIndex], // 選択された職業を表示
                  ),
                  decoration: InputDecoration(labelText: '職業'),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _saveUserInfo, child: Text('Save')),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _targetController.dispose();
    _occupationCotroller.dispose();
    super.dispose();
  }
}
