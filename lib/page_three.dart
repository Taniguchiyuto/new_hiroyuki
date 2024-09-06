import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PageThree extends StatelessWidget {
  final List<ChatItem> chatItems = [
    ChatItem("ひろゆき", "それってあなたの感想ですよね", "14:57", "assets/images/avatar1.png"),
    ChatItem("Alan", "", "昨日", "assets/images/avatar2.png"),
    ChatItem("バキ童", "バキバキ童貞です。", "金曜日", "assets/images/avatar3.png"),
    ChatItem("フーミン", "", "金曜日", "assets/images/avatar4.png"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("チャット"),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // 設定ボタンの処理
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: chatItems.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage(chatItems[index].avatarPath),
            ),
            title: Text(chatItems[index].name),
            subtitle: Text(chatItems[index].message),
            trailing: Text(chatItems[index].time),
            onTap: () {
              // チャット詳細画面に遷移
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(name: chatItems[index].name),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ChatItem {
  final String name;
  final String message;
  final String time;
  final String avatarPath;

  ChatItem(this.name, this.message, this.time, this.avatarPath);
}

class ChatScreen extends StatefulWidget {
  final String name;

  ChatScreen({required this.name});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> messages = [];

  // OpenAI APIキー

  // GPT APIを呼び出す関数
  Future<String> callGPTApi(String message) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {'role': 'system', 'content': 'You are a helpful assistant.'},
            {'role': 'user', 'content': message},
          ],
          'max_tokens': 100, // 返信の長さ
        }),
      );

      if (response.statusCode == 200) {
        // UTF-8でレスポンスをデコード
        final decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = json.decode(decodedBody);
        return responseData['choices'][0]['message']['content'].trim();
      } else {
        print('APIエラー: ${response.statusCode}');
        print('APIレスポンス: ${response.body}');
        return "APIエラーが発生しました。";
      }
    } catch (e) {
      print('エラー: $e');
      return "エラーが発生しました。";
    }
  }

  // メッセージを送信してAPIからの返信を受け取る
  Future<void> sendMessage(String message) async {
    setState(() {
      messages.add({"sender": "User", "text": message});
    });

    String gptReply = await callGPTApi(message); // GPT APIを呼び出す

    setState(() {
      messages.add({"sender": widget.name, "text": gptReply});
    });

    _controller.clear();

    // メッセージ送信後に自動で最新メッセージにスクロール
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name), // チャット相手の名前を表示
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                bool isUser = messages[index]['sender'] == "User";
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.all(10.0),
                    margin:
                        EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(
                      messages[index]['text']!,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "メッセージを送信",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.blue),
                    onPressed: () {
                      if (_controller.text.isNotEmpty) {
                        sendMessage(_controller.text);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
