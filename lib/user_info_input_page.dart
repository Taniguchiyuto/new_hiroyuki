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
  final TextEditingController _targetController =
      TextEditingController(); // target入力用コントローラ
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _occupationCotroller = TextEditingController();
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
          _targetController.text = userInfo['target'] ?? ''; // targetをセット
          _ageController.text = userInfo['age']?.toString() ?? '';
          _occupationCotroller.text = userInfo['occupation'] ?? '';
        });
      }
    }
  }

  Future<void> _saveUserInfo() async {
    if (widget.user != null &&
        _usernameController.text.isNotEmpty &&
        _targetController.text.isNotEmpty &&
        _ageController.text.isNotEmpty &&
        _occupationCotroller.text.isNotEmpty) {
      // Firestoreにユーザー情報を保存
      await _firestore.collection('users').doc(widget.user!.uid).set({
        'username': _usernameController.text, // 入力されたユーザー名
        'target': _targetController.text, // 入力された目標
        'email': widget.user!.email, // ユーザーのメールアドレス
        'occupation': _occupationCotroller.text, // 入力された職業
        'age': int.parse(_ageController.text), // 入力された年齢
        'studyRank': "A", // 固定値として 0 を保存
        'lifeRank': "A", // 固定値として 0 を保存
        'gradeRank': "A", // 固定値として 0 を保存
        'studySentence': "A",
        'lifeSentence': "A",
        'gradeSentence': "A"
      });

      // 保存後、ホームページに遷移
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()), // HomePageへ遷移
      );
    } else {
      // フィールドが空の場合はエラーメッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('全てのフィールドを入力してください')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ユーザー情報入力")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 画像を最初に表示
            Image.asset('assets/images/hiroyuki.png'),
            SizedBox(height: 20),
            // 画像の下にテキストを表示
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
              controller: _targetController, // target用のテキストフィールド
              decoration: InputDecoration(labelText: '目標'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _ageController,
              decoration: InputDecoration(labelText: '年齢'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _occupationCotroller,
              decoration: InputDecoration(labelText: '職業'),
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
    _targetController.dispose(); // targetコントローラの破棄
    _ageController.dispose();
    _occupationCotroller.dispose();
    super.dispose();
  }
}
