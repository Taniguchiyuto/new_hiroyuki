import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PageTwo extends StatefulWidget {
  @override
  _PageTwoState createState() => _PageTwoState();
}

class _PageTwoState extends State<PageTwo> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String uid = '未取得';
  String? selectedSubjectId;
  bool _isOrganizing = false; // 本棚整理モードのフラグを追加
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  Color _selectedColor = Colors.black; // デフォルトの色

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

  // 本棚整理モードを切り替える関数
  void _organizeShelf() {
    setState(() {
      _isOrganizing = !_isOrganizing;
    });
  }

  // 勉強時間を入力するダイアログを表示する関数
  void _showStudyTimeDialog(String subjectId, String materialId) {
    final TextEditingController _studyTimeController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('勉強時間を入力'),
          content: TextField(
            controller: _studyTimeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '勉強時間 (分)',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('保存'),
              onPressed: () async {
                double studyTime =
                    double.tryParse(_studyTimeController.text) ?? 0.0;
                await _incrementStudyTime(subjectId, materialId, studyTime);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 勉強時間をインクリメントする関数
  Future<void> _incrementStudyTime(
      String subjectId, String materialId, double studyTime) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    final String formattedDate =
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

    await _firestore.runTransaction((transaction) async {
      // 1. まず、必要なすべてのドキュメントを一括で読み取る
      final materialRef = _firestore
          .collection('subjects')
          .doc(subjectId)
          .collection('materials')
          .doc(materialId);

      DocumentSnapshot materialSnapshot = await transaction.get(materialRef);
      if (!materialSnapshot.exists) {
        throw Exception("教材が存在しません！");
      }

      double currentStudyTime = materialSnapshot['studyTime'] ?? 0.0;

      final studyLogRef =
          materialRef.collection('studyLogs').doc(formattedDate);
      DocumentSnapshot logSnapshot = await transaction.get(studyLogRef);
      double currentLogTime =
          logSnapshot.exists ? logSnapshot['studyTime'] ?? 0.0 : 0.0;

      // 2. その後に書き込み操作を行う
      transaction
          .update(materialRef, {'studyTime': currentStudyTime + studyTime});

      if (logSnapshot.exists) {
        transaction
            .update(studyLogRef, {'studyTime': currentLogTime + studyTime});
      } else {
        transaction.set(studyLogRef, {
          'date': formattedDate,
          'studyTime': studyTime,
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('勉強時間が保存されました')),
    );
  }

  // 編集ボタンが押されたときに表示するメニュー
  void _showEditMenu(BuildContext context, String subjectId) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.add),
                title: Text('新しい教材を追加'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddMaterialDialog(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.search_rounded),
                title: Text('本を検索'),
                onTap: () {
                  Navigator.pop(context);
                  _showSearchAndAddMaterialDialog(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.library_add),
                title: Text('新しい科目を追加'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddSubjectDialog(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('本棚を整理'),
                onTap: () {
                  Navigator.pop(context);
                  _organizeShelf();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('科目を削除'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteSubjectDialog(context, subjectId);
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel),
                title: Text('キャンセル'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 教材を削除する関数
  Future<void> _deleteMaterial(String subjectId, String materialId) async {
    await _firestore
        .collection('subjects')
        .doc(subjectId)
        .collection('materials')
        .doc(materialId)
        .delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('教材が削除されました')),
    );
  }

  // 科目を削除する関数
  Future<void> _deleteSubject(String subjectId) async {
    if (subjectId.isEmpty) {
      throw Exception('削除する科目が選択されていません');
    }

    final batch = _firestore.batch();
    final materialsSnapshot = await _firestore
        .collection('subjects')
        .doc(subjectId)
        .collection('materials')
        .get();

    for (var material in materialsSnapshot.docs) {
      batch.delete(material.reference);
    }

    final subjectRef = _firestore.collection('subjects').doc(subjectId);
    batch.delete(subjectRef);

    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('科目と関連する教材が削除されました')),
    );
  }

  // 本を検索して追加するためのモーダルを表示する関数
  void _showSearchAndAddMaterialDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('subjects')
              .where('uid', isEqualTo: uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return CircularProgressIndicator();
            final subjects = snapshot.data!.docs;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DropdownButton<String>(
                  hint: Text('科目を選択'),
                  value: selectedSubjectId,
                  onChanged: (value) {
                    setState(() {
                      selectedSubjectId = value;
                    });
                  },
                  items: subjects.map((subject) {
                    return DropdownMenuItem<String>(
                      value: subject.id,
                      child: Text(subject['name']),
                    );
                  }).toList(),
                ),
                Expanded(
                  child: BookSearchWidget(
                    subjectId: selectedSubjectId ?? '',
                    onBookSelected: (bookTitle) {
                      if (selectedSubjectId != null) {
                        _addStudyMaterial(bookTitle);
                      }
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 新しい科目を追加するダイアログを表示する関数
  void _showAddSubjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('新しい科目を追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _subjectController,
                decoration: InputDecoration(labelText: '科目名'),
              ),
              SizedBox(height: 16),
              Text('アイコンの色を選択:'),
              SizedBox(height: 8),
              Wrap(
                spacing: 8.0, // 間隔を設定
                children: [
                  _buildColorOption(Colors.red),
                  _buildColorOption(Colors.green),
                  _buildColorOption(Colors.blue),
                  _buildColorOption(Colors.yellow),
                  _buildColorOption(Colors.orange),
                  _buildColorOption(Colors.purple),
                  _buildColorOption(Colors.pink),
                  _buildColorOption(Colors.brown),
                  _buildColorOption(Colors.teal),
                  _buildColorOption(Colors.cyan),
                  _buildColorOption(Colors.lime),
                  _buildColorOption(Colors.indigo),
                  _buildColorOption(Colors.amber),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('追加'),
              onPressed: () {
                _addNewSubject();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 色の選択肢を作成するヘルパー関数
  Widget _buildColorOption(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
        });
      },
      child: CircleAvatar(
        backgroundColor: color,
        child: _selectedColor == color
            ? Icon(Icons.check, color: Colors.white)
            : null,
      ),
    );
  }

  // 教材追加のダイアログを表示する関数
  void _showAddMaterialDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('新しい教材を追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: '教材のタイトル'),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('subjects')
                    .where('uid', isEqualTo: uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();
                  final subjects = snapshot.data!.docs;
                  return DropdownButton<String>(
                    hint: Text('科目を選択'),
                    value: selectedSubjectId,
                    onChanged: (value) {
                      setState(() {
                        selectedSubjectId = value;
                      });
                    },
                    items: subjects.map((subject) {
                      return DropdownMenuItem<String>(
                        value: subject.id,
                        child: Text(subject['name']),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('追加'),
              onPressed: () {
                _addMaterial();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 科目を削除する確認ダイアログを表示する関数
  void _showDeleteSubjectDialog(BuildContext context, String subjectId) {
    if (subjectId.isEmpty) {
      // subjectIdが空の場合にエラーを防ぐためのチェック
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('削除する科目が選択されていません')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('科目を削除'),
          content: Text('この科目と関連するすべての教材を削除してもよろしいですか？'),
          actions: <Widget>[
            TextButton(
              child: Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('削除'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSubject(subjectId);
              },
            ),
          ],
        );
      },
    );
  }

  // 科目を追加する処理
  Future<void> _addNewSubject() async {
    if (_subjectController.text.isNotEmpty) {
      await _addSubject(_subjectController.text, _selectedColor);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('科目が正常に追加されました')),
      );
      setState(() {
        _subjectController.clear();
        _selectedColor = Colors.black; // デフォルトの色にリセット
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('科目名を入力してください')),
      );
    }
  }

  // 教材を追加する処理
  Future<void> _addMaterial() async {
    if (_titleController.text.isNotEmpty && selectedSubjectId != null) {
      await _addStudyMaterial(_titleController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('教材が正常に追加されました')),
      );
      setState(() {
        _titleController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('科目と教材のタイトルを入力してください')),
      );
    }
  }

  // Firestoreに科目データを保存する関数
  Future<void> _addSubject(String name, Color color) async {
    await _firestore.collection('subjects').add({
      'name': name,
      'color': color.value, // 色の値を保存
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Firestoreに教材データを保存する関数
  Future<void> _addStudyMaterial(String title) async {
    if (selectedSubjectId != null) {
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;

      // 1. `materials`コレクションに新しいドキュメントを追加
      final DocumentReference materialRef = await _firestore
          .collection('subjects')
          .doc(selectedSubjectId)
          .collection('materials')
          .add({
        'title': title,
        'createdAt': FieldValue.serverTimestamp(),
        'studyTime': 0.0, // 初期の総勉強時間
      });

      // 2. `studyLogs`サブコレクションに初期データを追加
      String formattedDate =
          "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

      await materialRef.collection('studyLogs').doc(formattedDate).set({
        'date': formattedDate,
        'studyTime': 0.0, // 初期の勉強時間を0に設定
      });
    }
  }

  // 科目ごとの教材を表示するウィジェット
  Widget _buildSubjectSections() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('subjects')
          .where('uid', isEqualTo: uid)
          .snapshots(),
      builder: (context, subjectSnapshot) {
        if (subjectSnapshot.hasError) {
          return Center(child: Text('エラーが発生しました: ${subjectSnapshot.error}'));
        }
        if (subjectSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!subjectSnapshot.hasData || subjectSnapshot.data!.docs.isEmpty) {
          return Center(child: Text('表示する科目がありません'));
        }

        final subjects = subjectSnapshot.data!.docs;

        return Stack(
          children: [
            ListView.builder(
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                final subjectData =
                    subject.data() as Map<String, dynamic>?; // データをMapとしてキャスト
                final subjectColor =
                    (subjectData != null && subjectData.containsKey('color'))
                        ? Color(subjectData['color'])
                        : Colors.black; // デフォルトの色を設定

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DragTarget<Map<String, dynamic>>(
                      onAccept: (data) async {
                        await _firestore
                            .collection('subjects')
                            .doc(data['subjectId'])
                            .collection('materials')
                            .doc(data['materialId'])
                            .delete();

                        await _firestore
                            .collection('subjects')
                            .doc(subject.id)
                            .collection('materials')
                            .add({
                          'title': data['title'],
                          'createdAt': FieldValue.serverTimestamp(),
                          'studyTime': 0.0, // 勉強時間フィールドを初期化
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('教材が移動されました')),
                        );
                      },
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          color: candidateData.isNotEmpty
                              ? Colors.grey[200]
                              : null, // ドラッグ中の視覚的フィードバックを追加
                          child: ListTile(
                            title: Text(
                                subjectData?['name'] ?? 'No Name'), // Nullチェック
                            leading: Icon(Icons.book, color: subjectColor),
                            onLongPress: () {
                              _showEditMenu(context, subject.id);
                            },
                          ),
                        );
                      },
                    ),
                    SizedBox(
                      height: 200,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('subjects')
                            .doc(subject.id)
                            .collection('materials')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, materialSnapshot) {
                          if (materialSnapshot.hasError) {
                            return Center(
                                child: Text(
                                    'エラーが発生しました: ${materialSnapshot.error}'));
                          }
                          if (materialSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (!materialSnapshot.hasData ||
                              materialSnapshot.data!.docs.isEmpty) {
                            return Center(child: Text('この科目に表示する教材がありません'));
                          }

                          final materials = materialSnapshot.data!.docs;

                          return GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                            ),
                            itemCount: materials.length,
                            itemBuilder: (context, materialIndex) {
                              final material = materials[materialIndex];

                              return _isOrganizing
                                  ? LongPressDraggable<Map<String, dynamic>>(
                                      data: {
                                        'materialId': material.id,
                                        'subjectId': subject.id,
                                        'title': material['title'],
                                      },
                                      feedback: Material(
                                        child: Card(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.insert_drive_file,
                                                  size: 40),
                                              SizedBox(height: 10),
                                              Text(material['title']),
                                            ],
                                          ),
                                        ),
                                      ),
                                      childWhenDragging: Opacity(
                                        opacity: 0.5,
                                        child: Card(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.insert_drive_file,
                                                  size: 40),
                                              SizedBox(height: 10),
                                              Text(material['title']),
                                            ],
                                          ),
                                        ),
                                      ),
                                      child: DragTarget<Map<String, dynamic>>(
                                        builder: (context, candidateData,
                                            rejectedData) {
                                          return Card(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.insert_drive_file,
                                                    size: 40),
                                                SizedBox(height: 10),
                                                Text(material['title']),
                                              ],
                                            ),
                                          );
                                        },
                                        onAccept: (data) async {
                                          if (data['subjectId'] == subject.id) {
                                            await _reorderMaterial(
                                              subject.id,
                                              data['materialId'],
                                              material.id,
                                            );
                                          } else {
                                            await _firestore
                                                .collection('subjects')
                                                .doc(data['subjectId'])
                                                .collection('materials')
                                                .doc(data['materialId'])
                                                .delete();

                                            await _firestore
                                                .collection('subjects')
                                                .doc(subject.id)
                                                .collection('materials')
                                                .add({
                                              'title': data['title'],
                                              'createdAt':
                                                  FieldValue.serverTimestamp(),
                                              'studyTime': 0.0, // 勉強時間フィールドを初期化
                                            });
                                          }

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text('教材が移動されました')));
                                        },
                                      ),
                                    )
                                  : GestureDetector(
                                      onTap: () {
                                        _showStudyTimeDialog(
                                            subject.id, material.id);
                                      },
                                      child: Card(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.insert_drive_file,
                                                size: 40),
                                            SizedBox(height: 10),
                                            Text(material['title']),
                                          ],
                                        ),
                                      ),
                                    );
                            },
                          );
                        },
                      ),
                    ),
                    Divider(),
                  ],
                );
              },
            ),
            if (_isOrganizing)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: DragTarget<Map<String, dynamic>>(
                  onAccept: (data) async {
                    await _deleteMaterial(
                        data['subjectId'], data['materialId']);
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      color: Colors.red,
                      height: 60,
                      child: Center(
                        child: Text(
                          candidateData.isNotEmpty
                              ? 'ここにドロップして削除'
                              : 'ドラッグしてここにドロップ',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  // Firestoreの教材順序を入れ替える関数
  Future<void> _reorderMaterial(
      String subjectId, String oldMaterialId, String newMaterialId) async {
    final batch = _firestore.batch();
    final oldMaterialRef = _firestore
        .collection('subjects')
        .doc(subjectId)
        .collection('materials')
        .doc(oldMaterialId);
    final newMaterialRef = _firestore
        .collection('subjects')
        .doc(subjectId)
        .collection('materials')
        .doc(newMaterialId);

    final oldMaterialData = await oldMaterialRef.get();
    final newMaterialData = await newMaterialRef.get();

    if (oldMaterialData.exists && newMaterialData.exists) {
      batch.update(oldMaterialRef, {'createdAt': newMaterialData['createdAt']});
      batch.update(newMaterialRef, {'createdAt': oldMaterialData['createdAt']});
      await batch.commit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('教材の管理'),
        actions: [
          if (_isOrganizing)
            IconButton(
              icon: Icon(Icons.cancel),
              onPressed: _organizeShelf, // 整理モードをキャンセルする
            ),
          IconButton(
            icon: Icon(Icons.more_vert), // 右上のボタン
            onPressed: () {
              _showEditMenu(context, ''); // ボタンが押されたときに編集メニューを表示する
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: _buildSubjectSections(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _titleController.dispose();
    super.dispose();
  }
}

// 新しい検索ウィジェットを追加します
class BookSearchWidget extends StatefulWidget {
  final String subjectId;
  final Function(String) onBookSelected;

  BookSearchWidget({required this.subjectId, required this.onBookSelected});

  @override
  _BookSearchWidgetState createState() => _BookSearchWidgetState();
}

class _BookSearchWidgetState extends State<BookSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _books = [];
  bool _loading = false;

  Future<void> _searchBooks() async {
    setState(() {
      _loading = true;
    });

    final apiKey =
        'AIzaSyAuaDS5E3JDnzicXr4tM3SgBAy8qUpy-4s'; // ここにGoogle Books APIキーを入力
    final query = _searchController.text;
    final response = await http.get(
      Uri.parse(
          'https://www.googleapis.com/books/v1/volumes?q=$query&key=$apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _books = data['items'] ?? [];
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
      });
      throw Exception('Failed to load books');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Books'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for books',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchBooks,
                ),
              ),
            ),
            SizedBox(height: 16),
            _loading
                ? CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: _books.length,
                      itemBuilder: (context, index) {
                        final book = _books[index]['volumeInfo'];
                        return ListTile(
                          title: Text(book['title']),
                          subtitle:
                              Text(book['authors']?.join(', ') ?? 'No authors'),
                          onTap: () {
                            widget.onBookSelected(book['title']);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
