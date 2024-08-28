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
        });
      }
    }
  }

  Future<void> _saveUserInfo() async {
    if (widget.user != null && _usernameController.text.isNotEmpty) {
      await _firestore.collection('users').doc(widget.user!.uid).set({
        'username': _usernameController.text,
        'email': widget.user!.email,
      });

      // 保存後にホームページに遷移
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      // 空のフィールドがある場合は警告を表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ユーザー名を入力してください')),
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
              decoration: InputDecoration(labelText: 'Username'),
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
    super.dispose();
  }
}
