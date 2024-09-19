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

  String studyRank = 'A';
  String lifeRank = 'B';
  String gradeRank = 'A';
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
    _loadTarget();
    _getStudyRecords();
  }

  // Firestoreから現在のユーザーのtargetを取得するメソッド
  Future<void> _loadTarget() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          var userData = userDoc.data() as Map<String, dynamic>;
          if (userData.containsKey('target')) {
            setState(() {
              target = userData['target']; // 取得したtargetをセット
            });
            print('取得した目標: $target'); // 取得した目標をログに出力
          } else {
            print('targetフィールドが存在しません');
          }
        } else {
          print('ユーザー情報が存在しません');
        }
      } else {
        print('ユーザーがログインしていません');
      }
    } catch (e) {
      print('エラーが発生しました: $e');
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
        '--- 学習記録 ---\n$studyRecordsText\n'
        '以下は例です。この例を参考に$studyRecordsTextの評価をして下さい\n'
        '例1:京大経済学部文系志望の浪人生が一対一対応の数学、古文、長文ルールズをそれぞれ5時間勉強しました。これを評価してみて下さい。\n'
        '---解答---\n'
        'ステップ1: 目標達成に必要な点数と偏差値の目安\n'
        '京都大学の経済学部文系に合格するためには、共通テストで概ね85%以上の得点が必要です。特に二次試験では、英語、数学、国語が重要で、偏差値でいうと65～70程度が目安です。また、京大は論述力も問われるため、深い理解と応用力が必要です。\n'
        'ステップ2: 必要とされる基準 浪人生の場合、高校生と違って基礎の定着はもちろん、応用力や過去問演習、論述対策も必要です。また、全体的に一週間あたりの学習時間は少なくとも40～50時間以上が推奨されます。特に京大は数学や論述の難易度が高いので、重点的な対策が求められます。\n'
        'ステップ3: 科目バランスと現在の学習内容との乖離\n'
        '数学:5時間\n'
        '一対一対応の数学に5時間は、浪人生としては少し不足しています。京大経済学部は文系ですが、数学のレベルが非常に高いため、数学に少なくとも10～15時間は必要です。特に問題演習や応用問題の解法をしっかりと取り組む必要があります。\n'
        '古文:5時間\n'
        '古文に5時間は適切な時間配分です。古典文法や読解力は既に身についていることを前提に、過去問や論述対策にも取り組んでいると良いでしょう。\n'
        '英語（長文ルールズ:5時間\n'
        '英語長文に5時間というのも少し少ない印象です。京大の英語は難易度が高く、長文読解だけでなく、文法や英作文、特に論述対策が必要です。10時間程度かけても良いでしょう。\n';
    '総合評価:D \n'
        '現在の勉強は科目バランス自体は悪くありませんが、浪人生としては学習時間が大きく不足しています。全体で15時間の学習時間は、特に京大のレベルを考えるとやや少ないです。また、数学と英語は京大の二次試験において非常に重要であり、各科目の勉強時間を増やす必要があります。\n'
        '改善点:数学の勉強時間を増やす:10～15時間を目安に応用問題や過去問演習を積極的に取り組んでください。\n'
        '英語の強化：長文読解だけでなく、英作文や論述対策に重点を置いて、勉強時間を倍にすることを目指しましょう。\n'
        '全体の学習時間を増やす:一週間で40～50時間の学習を目指し、バランスよく他の科目も取り入れましょう。'
        '浪人生としては、まだ全体的に時間が足りないため、学習時間を増やしつつ効率よく進めることが合格への鍵です。頑張ってください！\n'
        '例2:横浜国立大学の経済学部文系の大学入学試験の合格を目指している高校一年生が1対1対応の演習/数学Bを1222分行いました\n'
        '---解答---\n'
        'ステップ1: 目標達成に必要な点数と偏差値の目安  横浜国立大学経済学部文系に合格するためには、共通テストでおおむね75～80%の得点が必要です。特に二次試験では、英語と数学が重要で、偏差値でいうと60～65程度が目安です。特に経済学部なので、数学は他の文系学部よりも重視されます。\n'
        'ステップ2: 高校1年生時点で必要とされる基準 現時点では基礎の定着が重要です。特に数学、英語、国語は早めにしっかりと基礎を固める必要があります。週の学習時間としては、少なくとも15〜20時間が理想的です。これによって、各科目のバランス良い学習が可能となり、早い段階で基礎力を定着させることができるでしょう。\n'
        'ステップ3: 科目バランスと現在の学習内容との乖離 数学 勉強時間: 1222分（約20時間） 教材: 1対1対応の演習/数学B 価: 非常に優れています。数学に20時間を割いているのは、高校1年生としては非常に良いペースです。この時点でこれだけの時間をかけて数学の基礎固めをしていることは、今後の学習に大いに役立つでしょう。ただし、他の科目とのバランスが課題となります。他の科目勉強なし\n'
        '総合評価: D 理由: 数学に対する時間の使い方は素晴らしいですが、他の科目、特に英語や国語が全く学習されていない点が問題';

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

      // 返答をUTF-8でデコードして取得
      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
        String gptResponse =
            decodedResponse['choices'][0]['message']['content'];

        // 手動で作成したファイルのパスを指定
        final file =
            File('/Users/makikotaniguchi/gpt_response.txt'); // 画像で確認されたパス
        // 手動で作成したファイルのフルパスを指定

        // ファイルにGPTの返答を書き込む
        await file.writeAsString(gptResponse);

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
