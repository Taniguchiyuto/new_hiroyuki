import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PageTwo extends StatefulWidget {
  @override
  _PageTwoState createState() => _PageTwoState();
}

class _PageTwoState extends State<PageTwo> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String uid = '未取得';
  final TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentUserUID();
  }

  // ログインしているユーザーのUIDを取得する関数
  Future<void> _getCurrentUserUID() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        uid = user.uid;
      });
    } else {
      setState(() {
        uid = 'ログインしていません';
      });
    }
  }

  // Firestoreに教材データを保存する関数
  Future<void> _addStudyMaterial(String title) async {
    await _firestore
        .collection('study_materials')
        .doc(uid) // UIDをドキュメントIDとして使用
        .collection('materials') // サブコレクション
        .add({
      'title': title,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 教材を追加する処理
  Future<void> _addMaterial() async {
    if (_titleController.text.isNotEmpty) {
      await _addStudyMaterial(_titleController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('教材が正常に追加されました')),
      );
      setState(() {
        _titleController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('タイトルを入力してください')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('教材の管理')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 教材タイトルの入力フィールド
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: '教材のタイトル'),
            ),
            SizedBox(height: 20),
            // 教材追加ボタン
            ElevatedButton(
              onPressed: _addMaterial,
              child: Text('教材を追加'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder(
                stream: _firestore
                    .collection('study_materials')
                    .doc(uid)
                    .collection('materials')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('表示する教材がありません'));
                  }

                  final materials = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: materials.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(materials[index]['title']),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}
