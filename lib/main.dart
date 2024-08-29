import 'package:flutter/material.dart';
import 'auth_screen.dart'; // ログイン画面をインポート
import 'home_page.dart'; // HomePageをインポート
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuthをインポート
import 'package:firebase_core/firebase_core.dart'; // Firebase初期化をインポート

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutterの初期化
  await Firebase.initializeApp(); // Firebaseの初期化
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: InitialScreen(), // 最初に表示する画面をInitialScreenに設定
    );
  }
}

class InitialScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // FirebaseAuthを使って現在のユーザーを取得
    User? user = FirebaseAuth.instance.currentUser;

    // ユーザーがログインしているかどうかを確認
    if (user != null) {
      // ユーザーがログインしている場合、HomePageに遷移
      return HomePage();
    } else {
      // ユーザーがログインしていない場合、AuthScreenに遷移
      return AuthScreen();
    }
  }
}
