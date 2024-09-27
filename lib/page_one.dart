import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 日付フォーマット用のパッケージをインポート
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuthをインポート
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // dotenvをインポート
// import 'package:path_provider/path_provider.dart'; // パスを取得するためのパッケージ（モバイル用の例）

class PageOne extends StatefulWidget {
  @override
  _StudyMindUIState createState() => _StudyMindUIState();
}

class _StudyMindUIState extends State<PageOne> {
  String target = '目標未設定';
  // studyRecordsをクラス全体で使えるようにメンバ変数として定義
  List<Map<String, dynamic>> studyRecords = [];

  String studyRank = '未設定';
  String lifeRank = '未設定';
  String gradeRank = '未設定';
  String comment = "評価のポイント\n" +
      "1. 成績（B+）: 成績自体は十分に優秀で、目標に向けて着実に進んでいる状態です。\n" +
      "2. 学習（B+）: 学習習慣も良好で、しっかりとした時間と集中力が確保できている様子です。\n" +
      "3. 生活習慣（B-）: 生活習慣がやや他の要素に比べて低めです。\n\n" +
      "総合評価: B+\n" +
      "良い点: 学習と成績は良好な状態を保っており、全体としても高い評価が可能です。\n" +
      "改善点: 生活習慣をもう少し整えることで、他の部分にもプラスの影響を与える可能性があります。\n\n" +
      "アドバイス\n" +
      "- 生活習慣の見直し: 毎日のルーティンや睡眠時間の調整などを試みる。\n" +
      "- 現状維持と向上: 学習の調子を保ちながら、成績をさらに向上させる。";

  String overallEvaluation =
      "総合評価はSです。学習、生活、成績の各分野において全体的に優れており、特に学習と成績が高い評価を受けています。";

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _getStudyRecords();
  }

  // Firestoreから現在のユーザーのデータ (target, studyRank, lifeRank, gradeRank) を取得するメソッド
  Future<void> _loadUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Firestoreからユーザードキュメントを取得
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          var userData = userDoc.data() as Map<String, dynamic>;

          // 各フィールドの存在チェックとセット
          setState(() {
            target =
                userData.containsKey('target') ? userData['target'] : '目標未設定';
            studyRank = userData.containsKey('studyRank')
                ? userData['studyRank']
                : '未設定';
            lifeRank =
                userData.containsKey('lifeRank') ? userData['lifeRank'] : '未設定';
            gradeRank = userData.containsKey('gradeRank')
                ? userData['gradeRank']
                : '未設定';
            comment = userData.containsKey('studySentence')
                ? userData['studySentence']
                : '評価のポイント未設定';
          });

          // ログで確認
          print(
              '取得したデータ: 目標: $target, 学習評価: $studyRank, 生活評価: $lifeRank, 成績評価: $gradeRank');
        } else {
          print('ユーザードキュメントが存在しません');
        }
      } else {
        print('ユーザーがログインしていません');
      }
    } catch (e) {
      print('エラーが発生: $e');
    }
  }

  // Firestoreからユーザーの学習記録を取得して、クラス変数にセットするメソッド
  Future<void> _getStudyRecords() async {
    List<Map<String, dynamic>> tempStudyRecords = [];

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('ユーザーID : ${user.uid}');
      } else {
        print('ユーザーがログインしていません');
        return; // ユーザーがいない場合処理を中止
      }

      if (user != null) {
        // 現在の日付を取得し、前日から1週間前までの範囲を計算
        DateFormat dateFormat = DateFormat('yyyy-MM-dd');
        DateTime today = DateTime.now();
        DateTime endDate = today.subtract(Duration(days: 1)); // 前日
        DateTime startDate = endDate.subtract(Duration(days: 6)); // 1週間前
        String formattedStartDate = dateFormat.format(startDate);
        String formattedEndDate = dateFormat.format(endDate); // 1週間前まで
        print(
            'startDate: $formattedStartDate, endDate: $formattedEndDate'); // ここで日付範囲を確認

        // Firestoreクエリ：ユーザーIDに基づいてsubjectsを取得
        QuerySnapshot subjectSnapshot = await FirebaseFirestore.instance
            .collection('subjects')
            .where('uid', isEqualTo: user.uid) // subjectsコレクションをUIDでフィルタリング
            .get();

        if (subjectSnapshot.docs.isEmpty) {
          print('科目データが見つかりません');
        } else {
          print('取得した科目データ : ${subjectSnapshot.docs.length}');
        }

        // 各subjectに関連するstudyLogsを取得
        for (var subjectDoc in subjectSnapshot.docs) {
          // 科目名の取得
          String subjectName = subjectDoc['name'];
          print(subjectDoc.id);

          QuerySnapshot materialsSnapshot = await FirebaseFirestore.instance
              .collection('subjects')
              .doc(subjectDoc.id)
              .collection('materials')
              .get();
          print('取得した教材数: ${materialsSnapshot.docs.length}');

          for (var materialDoc in materialsSnapshot.docs) {
            // 教材ごとのstudyLogsを取得
            QuerySnapshot studyLogSnapshot = await FirebaseFirestore.instance
                .collection('subjects')
                .doc(subjectDoc.id)
                .collection('materials')
                .doc(materialDoc.id)
                .collection('studyLogs')
                .where('date', isGreaterThanOrEqualTo: formattedStartDate)
                .where('date', isLessThanOrEqualTo: formattedEndDate)
                .get();

            print('取得したstudyLogs: ${studyLogSnapshot.docs.length}件');

            // studyLogsごとの情報をリストに追加
            for (var studyLogDoc in studyLogSnapshot.docs) {
              Map<String, dynamic> studyLog =
                  studyLogDoc.data() as Map<String, dynamic>;

              print('学習記録の内容: ${studyLog.toString()}');

              tempStudyRecords.add({
                '勉強した科目': subjectName,
                '勉強時間': studyLog['studyTime'],
                '勉強した教材名': materialDoc['title'],
                '勉強した日にち': studyLog['date']
              });
            }
          }
        }

        // 取得したデータをsetStateで保存
        setState(() {
          studyRecords = tempStudyRecords;
        });
      }
    } catch (e) {
      print('エラーが発生しました: $e');
    }
    print('最終的な学習記録: $studyRecords');
  }

  // 簡易化したAPIリクエスト（修正済み）

  Future<void> sendSimpleTestToGPT() async {
    final url = 'https://api.openai.com/v1/chat/completions'; // エンドポイント

    String studyrank = "未設定";

    // OpenAI APIキーを挿入してください
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print('APIキーが設定されていません。環境変数を確認してください。');
      return;
    }

    // studyRecordsをテキストに変換
    String studyRecordsText = studyRecords.map((record) {
      return '科目: ${record['勉強した科目']},時間: ${record['勉強時間']}分,教材: ${record['勉強した教材名']},日付: ${record['勉強した日にち']}';
    }).join('\n');

    // シンプルな固定テキストをpromptとして送信
    String simplePrompt =
        'あなたは優秀な勉強サポートアプリのコーチです。相手は高校一年生で、大学受験生です。横浜国立大学の経済学部文系の大学入学試験の合格を目指しています。以下の一週間の学習記録に基づいて、A〜Fの評価を行ってください。目標はアプリの利用者の学習の分析です\n'
        '以下の思考フローを用いて、ステップバイステップで絞り込んでいくことを想定してください。\n'
        'ステップ1:横浜国立大学の経済学部文系を合格するのに必要な共通テストのボーダーと、二次試験で必要な科目とその偏差値の目安をパスナビで調べる。\n'
        'ステップ2:科目のバランスを考えた上で、高校一年生の時点で目標を達成するために必要とされる基準を調べる。\n'
        'ステップ3:科目のバランスも踏まえ、その基準と現在の勉強との乖離を元に一週間の総合計学習を評価する'
        '評価は以下の基準に従ってください。\n'
        '--- A〜Fの評価基準 ---\n'
        'A: 非常に優れている。学習時間や内容が十分で、バランスが取れている。\n'
        'B: 優れている。学習は良好で、少しの改善でさらに良い成果が得られる。\n'
        'C: 平均的。学習は標準的だが、改善が必要な点がある。\n'
        'D: やや不足している。学習量や内容がやや足りず、進展が遅れている。\n'
        'E: 大幅に不足している。学習量が不足しており、目標達成が難しい。\n'
        'F: 全く不十分。学習がほとんどできておらず、大きな改善が必要。\n\n'
        '--- 学習記録 ---$studyRecordsText';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4', // 使用する新しいモデル
          'messages': [
            {
              'role': 'system',
              'content':
                  'あなたは勉強サポートアプリのコーチです。要点を絞ったフィードバックを提供してください。A〜Fの評価と簡単なアドバイスに留めてください。より詳細な回答をするようにして下さい。目安は4000トークンです。'
            },
            {'role': 'user', 'content': simplePrompt}
          ],
          'max_tokens': 4000
        }),
      );

      Future<void> _saveGPTResponseToFirestore(String gptResponse) async {
        User? user = FirebaseAuth.instance.currentUser; // 現在のユーザーを取得
        if (user != null) {
          try {
            // FirestoreのユーザードキュメントにgptResponseをstudySentenceフィールドとして保存
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({
              'studySentence': gptResponse, // GPTの応答をstudySentenceフィールドに保存
            });
            print('GPTの応答がFirestoreのstudySentenceフィールドに保存されました');
          } catch (e) {
            print('Firestoreへの保存中にエラーが発生しました: $e');
          }
        } else {
          print('ユーザーがログインしていません');
        }
      }

      // 返答をUTF-8でデコードして取得
      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
        String gptResponse =
            decodedResponse['choices'][0]['message']['content'];

        // 手動で作成したファイルのパスを指定
        // final file =
        //     File('/Users/makikotaniguchi/gpt_response.txt'); // 画像で確認されたパス
        // 手動で作成したファイルのフルパスを指定

        // ファイルにGPTの返答を書き込む
        await _saveGPTResponseToFirestore(gptResponse);
        print('GPTの返答がファイルに保存されました: /path/to/your/file/gpt_response.txt');
      } else {
        print('エラーが発生しました: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('例外が発生しました: $e');
    }
  }

  // ボタンを押したときに簡易化したAPIリクエストを送信
  void _onSimpleTestPressed() async {
    await sendSimpleTestToGPT();
  }

  // 前日から1週間前までの日付範囲を計算するメソッド
  String _getDateRange() {
    DateTime today = DateTime.now();
    DateTime endDate = today.subtract(Duration(days: 1)); // 前日
    DateTime startDate = endDate.subtract(Duration(days: 6)); // 1週間前まで

    // 日付フォーマットを指定 (例: 9月4日)
    DateFormat dateFormat = DateFormat('M月d日');
    String formattedStartDate = dateFormat.format(startDate);
    String formattedEndDate = dateFormat.format(endDate);

    return '$formattedStartDate ~ $formattedEndDate';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'StudyMind',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 目標表示
            Text(
              '目標: $target',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            // 総合評価セクションを上部に移動
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade100, Colors.blue.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '総合評価',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'S',
                          style: TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildEvaluationBox(
                          "学習習慣", studyRank, Colors.green.shade200),
                      SizedBox(height: 8),
                      _buildEvaluationBox(
                          "生活習慣", lifeRank, Colors.orange.shade200),
                      SizedBox(height: 8),
                      _buildEvaluationBox(
                          "成績", gradeRank, Colors.blue.shade200),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // 日付範囲 (前日から1週間前までを表示)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 18, color: Colors.grey[800]),
                  SizedBox(width: 8),
                  Text(
                    _getDateRange(), // 前日から1週間前の日付範囲を表示
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // 学習、生活、成績のセクション
            Expanded(
              child: ListView(
                children: [
                  // 総合評価タイルの追加
                  _buildExpansionTile("総合評価", "総合評価に関する内容", overallEvaluation),
                  _buildExpansionTile("学習習慣", "学習習慣に関する内容", comment),
                  _buildExpansionTile(
                      "生活習慣", "生活習慣に関する内容", "生活の詳細な内容がここに表示されます"),
                  _buildExpansionTile("成績", "成績に関する内容", "成績に関する詳細がここに表示されます"),
                ],
              ),
            ),

            // GPTに送信する簡易テスト用ボタンを追加
            ElevatedButton(
              onPressed: _onSimpleTestPressed, // 簡易テストを送信するボタン
              child: Text('GPTに簡易テスト送信'),
            ),
          ],
        ),
      ),
    );
  }

  // 評価ボックスウィジェット
  Widget _buildEvaluationBox(String title, String grade, Color color) {
    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2.0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color.darken(),
            ),
          ),
          Text(
            grade,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color.darken(),
            ),
          ),
        ],
      ),
    );
  }

  // 詳細を展開するタイルウィジェット
  Widget _buildExpansionTile(String title, String subtitle, String content) {
    return ExpansionTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      subtitle: Text(subtitle),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// 色の明るさを少し暗くする拡張メソッド
extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final darkened =
        hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkened.toColor();
  }
}
