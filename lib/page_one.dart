import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuthをインポート
import 'auth_screen.dart'; // ログイン画面をインポート
import 'package:intl/intl.dart'; // 日付フォーマット用のパッケージ

class PageOne extends StatefulWidget {
  @override
  _PageOneState createState() => _PageOneState();
}

class _PageOneState extends State<PageOne> {
  DateTime targetDate = DateTime(2024, 12, 31); // デフォルトのターゲット日
  String formattedTargetDate = "設定されていません"; // 初期状態

  // ユーザーIDを保存する変数
  String uid = "未取得"; // 初期状態では未取得

  @override
  void initState() {
    super.initState();
    _loadUid(); // 初期化時にUIDを取得
  }

  // UIDを取得するメソッド
  Future<void> _loadUid() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        uid = user.uid; // UIDを取得して設定
      });
    }
  }

  // カウントダウンのロジック
  Duration _calculateCountdown() {
    DateTime now = DateTime.now(); // 現在の日付
    return targetDate.difference(now); // 目標日までの日数差を計算
  }

  // 日付を選択するメソッド
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: targetDate, // 初期表示される日付
      firstDate: DateTime.now(), // 過去の日付は選べないように現在日付を最小日付に設定
      lastDate: DateTime(2101), // 将来の日付を最大に設定
    );
    if (picked != null && picked != targetDate) {
      setState(() {
        targetDate = picked; // pickedがnullでない場合のみ代入
        formattedTargetDate =
            DateFormat('yyyy/MM/dd').format(targetDate); // 日付をフォーマットして表示
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Duration countdown = _calculateCountdown(); // カウントダウンを計算

    return Scaffold(
      appBar: AppBar(
        title: Text("ホーム"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              // FirebaseAuthからサインアウト
              await FirebaseAuth.instance.signOut();

              // サインアウト後、ログイン画面に遷移
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AuthScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Welcome to the Home Page!",
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            Text(
              "あなたのUID: $uid", // UIDを表示
              style: TextStyle(fontSize: 16, color: Colors.blue),
            ),
            SizedBox(height: 40),
            Text(
              "大切なイベントまでのカウントダウン",
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            Text(
              "${countdown.inDays}日",
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
            Text(
              "イベントの日付: $formattedTargetDate",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _selectDate(context), // 日付選択のダイアログを開く
              child: Text('イベントの日付を設定'),
            ),
          ],
        ),
      ),
    );
  }
}
