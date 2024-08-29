import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuthをインポート
import 'auth_screen.dart'; // ログイン画面をインポート

class PageOne extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home Page"),
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
        child: Text("Welcome to the Home Page!"),
      ),
    );
  }
}
