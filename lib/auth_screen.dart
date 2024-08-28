import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'home_page.dart';
import 'user_info_input_page.dart'; // ユーザー情報入力ページのインポート
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestoreのインポート

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Firestoreインスタンスを作成
  String _email = '';
  String _password = '';
  String _message = '';

  Future<void> _createAccount() async {
    try {
      UserCredential userCredential =
          await _authService.createUser(_email, _password);
      setState(() {
        _message = "${userCredential.user?.email}のメールアドレスでアカウント登録することができました";
      });
    } catch (e) {
      setState(() {
        _message = e is FirebaseAuthException
            ? "Failed to create account: ${e.message}"
            : "An unexpected error occurred: ${e.toString()}";
      });
    }
  }

  Future<void> _login() async {
    try {
      UserCredential userCredential =
          await _authService.signInUser(_email, _password);
      setState(() {
        _message = "${userCredential.user?.email}としてログインできました";
      });

      if (userCredential.user != null) {
        // Firestoreからユーザー情報を取得
        DocumentSnapshot userInfo = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        // ドキュメントが存在しない、または「username」フィールドが存在しない、もしくは空白の場合
        if (!userInfo.exists ||
            userInfo['username'] == null ||
            userInfo['username'].toString().isEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UserInfoInputPage(
                user: userCredential.user,
                message: "ユーザー名を適当にでもいいので入力してもらってもいいですか？",
              ),
            ),
          );
        } else {
          // ユーザー情報が存在し、usernameフィールドが空でない場合、ホームページに遷移
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        }
      }
    } catch (e) {
      setState(() {
        _message = e is FirebaseAuthException
            ? "Failed to sign in: ${e.message}"
            : "An unexpected error occurred during sign in: ${e.toString()}";
      });
    }
  }

  Future<void> _resetPassword() async {
    try {
      await _authService.resetPassword(_email);
      setState(() {
        _message = "パスワードリセットのリンクが ${_email} に送信されました。メールを確認してください。";
      });
    } catch (e) {
      setState(() {
        _message = e is FirebaseAuthException
            ? "パスワードリセットに失敗しました: ${e.message}"
            : "Failed to reset password: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Firebase Auth")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: (value) => setState(() => _email = value),
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              onChanged: (value) => setState(() => _password = value),
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createAccount,
              child: Text('Create Account'),
            ),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
            ElevatedButton(
              onPressed: _resetPassword,
              child: Text('Forgot Password?'),
            ),
            SizedBox(height: 20),
            Text(_message),
          ],
        ),
      ),
    );
  }
}
