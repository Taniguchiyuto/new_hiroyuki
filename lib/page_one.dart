import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 日付フォーマット用のパッケージをインポート
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuthをインポート
import 'package:cloud_firestore/cloud_firestore.dart';

class PageOne extends StatefulWidget {
  @override
  _StudyMindUIState createState() => _StudyMindUIState();
}

class _StudyMindUIState extends State<PageOne> {
  String target = '目標未設定';
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

  bool operator ==(Object other) {
    // TODO: implement ==
    return super == other;
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
