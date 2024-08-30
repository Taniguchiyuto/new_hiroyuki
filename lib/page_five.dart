import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PageFive extends StatefulWidget {
  @override
  _PageFiveState createState() => _PageFiveState();
}

class _PageFiveState extends State<PageFive> {
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
      throw Exception('Failed to load books');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings Page with Book Search'),
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
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
