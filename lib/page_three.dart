import 'package:flutter/material.dart';
import 'main.dart'; // UserInfoInputPageをインポート
import 'package:firebase_auth/firebase_auth.dart';

class PageThree extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("オンライン自習室"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'オンライン自習室へようこそ！',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // 自習室に入室する処理を追加
              },
              child: Text('自習室に入る'),
            ),
            SizedBox(height: 20),
            Text(
              '現在の参加者:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('ユーザー1'),
                    subtitle: Text('勉強中'),
                  ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('ユーザー2'),
                    subtitle: Text('休憩中'),
                  ),
                  // 追加のユーザーを表示するリスト
                ],
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _logout(context); // ログアウト処理を呼び出し
              },
              child: Text('ログアウト'),
            ),
          ],
        ),
      ),
    );
  }

  // ログアウト処理
  Future<void> _logout(BuildContext context) async {
    try {
      // Firebaseからのログアウト処理を実行
      await FirebaseAuth.instance.signOut(); // Firebaseのログアウト処理

      // ログアウト成功のダイアログ表示
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("ログアウト完了"),
            content: Text("正常にログアウトしました。"),
            actions: [
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop(); // ダイアログを閉じる

                  // ログアウト成功後、UserInfoInputPageに遷移
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InitialScreen(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      // ログアウトエラーのダイアログ表示
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("エラー"),
            content: Text("ログアウトに失敗しました: $e"),
            actions: [
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop(); // ダイアログを閉じる
                },
              ),
            ],
          );
        },
      );
    }
  }
}
