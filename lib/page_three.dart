import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuthをインポート

class PageThree extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Page Three"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('AIチャット機能はまだ実装途中です。'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _logout(context);
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
      await FirebaseAuth.instance.signOut(); // Firebaseからのログアウト

      // ログアウト成功のダイアログを表示
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
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      print("ログアウトに失敗しました: $e");
      // エラーメッセージを表示
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
