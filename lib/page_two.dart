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
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

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

  // 編集ボタンが押されたときに表示するメニュー
  void _showEditMenu(BuildContext context) {
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
          content: TextField(
            controller: _subjectController,
            decoration: InputDecoration(labelText: '科目名'),
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

  // 本棚を整理する処理
  void _organizeShelf() {
    // 本棚整理の処理をここに実装
  }

  // 科目を追加する処理
  Future<void> _addNewSubject() async {
    if (_subjectController.text.isNotEmpty) {
      await _addSubject(_subjectController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('科目が正常に追加されました')),
      );
      setState(() {
        _subjectController.clear();
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
  Future<void> _addSubject(String name) async {
    await _firestore.collection('subjects').add({
      'name': name,
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Firestoreに教材データを保存する関数
  Future<void> _addStudyMaterial(String title) async {
    if (selectedSubjectId != null) {
      await _firestore
          .collection('subjects')
          .doc(selectedSubjectId)
          .collection('materials')
          .add({
        'title': title,
        'createdAt': FieldValue.serverTimestamp(),
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

        return ListView.builder(
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            final subject = subjects[index];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text(subject['name']),
                  leading: Icon(Icons.book),
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
                            child:
                                Text('エラーが発生しました: ${materialSnapshot.error}'));
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
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                        ),
                        itemCount: materials.length,
                        itemBuilder: (context, materialIndex) {
                          final material = materials[materialIndex];
                          return Card(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.insert_drive_file, size: 40),
                                SizedBox(height: 10),
                                Text(material['title']),
                              ],
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('教材の管理'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              _showEditMenu(context);
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
