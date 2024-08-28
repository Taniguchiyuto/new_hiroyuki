import 'package:flutter/material.dart';

class PageTwo extends StatefulWidget {
  @override
  _PageTwoState createState() => _PageTwoState();
}

class _PageTwoState extends State<PageTwo> {
  Map<String, List<Map<String, dynamic>>> categories = {
    "英語": [
      {"title": "英語", "icon": Icons.book},
    ],
    "古文": [
      {"title": "古文", "icon": Icons.book},
      {"title": "【基礎S】トップ古文論述", "icon": Icons.book},
      {"title": "うた恋い。超訳百人一首", "icon": Icons.book},
    ],
    "数学": [
      {"title": "数学の教材1", "icon": Icons.book},
      {"title": "数学の教材2", "icon": Icons.book},
      {"title": "数学の教材3", "icon": Icons.book},
    ],
  };

  void _addBook(String category, String title, IconData icon) {
    setState(() {
      categories[category]?.add({"title": title, "icon": icon});
    });
  }

  void _showAddBookDialog() {
    String category = '英語';
    String title = '';
    IconData selectedIcon = Icons.book;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("新しい教材を追加"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: category,
                items: categories.keys.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    category = value!;
                  });
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: "タイトル"),
                onChanged: (value) {
                  title = value;
                },
              ),
              DropdownButton<IconData>(
                value: selectedIcon,
                items: [
                  DropdownMenuItem(
                    child: Text("書籍"),
                    value: Icons.book,
                  ),
                  DropdownMenuItem(
                    child: Text("編集"),
                    value: Icons.edit,
                  ),
                  DropdownMenuItem(
                    child: Text("テスト"),
                    value: Icons.assignment,
                  ),
                  DropdownMenuItem(
                    child: Text("顔"),
                    value: Icons.face,
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedIcon = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text("キャンセル"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("追加"),
              onPressed: () {
                if (title.isNotEmpty) {
                  _addBook(category, title, selectedIcon);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showOptionsDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text("新しい教材を追加"),
              onTap: () {
                Navigator.of(context).pop();
                _showAddBookDialog();
              },
            ),
            ListTile(
              title: Text("本棚を整理"),
              onTap: () {
                // 本棚を整理する処理を追加
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: Text("キャンセル"),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("勉強中の本棚"),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _showOptionsDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: categories.keys.map((category) {
            return _buildCategorySection(category, categories[category]!);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategorySection(
      String categoryTitle, List<Map<String, dynamic>> bookList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            categoryTitle,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: bookList.map((book) {
            return Card(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(book["icon"], size: 40),
                  SizedBox(height: 8),
                  Text(
                    book["title"],
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
