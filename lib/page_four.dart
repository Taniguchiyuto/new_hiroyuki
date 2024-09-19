import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PageFour extends StatefulWidget {
  @override
  _PageFourState createState() => _PageFourState();
}

class _PageFourState extends State<PageFour> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? selectedMaterialTitle;
  DateTime? targetDate;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('学習時間レポート'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Table(
              columnWidths: const <int, TableColumnWidth>{
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  children: [
                    _buildStudyTimeHeaderCell("今日"),
                    _buildStudyTimeHeaderCell("今月"),
                    _buildStudyTimeHeaderCell("総計"),
                  ],
                ),
                TableRow(
                  children: [
                    StreamBuilder<double>(
                      stream: _getTodayStudyTimeStream(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return _buildStudyTimeDataCell(0);
                        }
                        return _buildStudyTimeDataCell(snapshot.data!);
                      },
                    ),
                    StreamBuilder<double>(
                      stream: _getThisMonthStudyTimeStream(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return _buildStudyTimeDataCell(0);
                        }
                        return _buildStudyTimeDataCell(snapshot.data!);
                      },
                    ),
                    StreamBuilder<double>(
                      stream: _getTotalStudyTimeStream(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return _buildStudyTimeDataCell(0);
                        }
                        return _buildStudyTimeDataCell(snapshot.data!);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          StreamBuilder<List<BarChartGroupData>>(
            stream: _getBarChartStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No data available'));
              }

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0), // 横のパディングを調整
                child: Column(
                  children: [
                    SizedBox(height: 10), // 上の表とのスペースを追加
                    InkWell(
                      onTap: () {
                        //ここで別ページに遷移する
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SecondPage()),
                        );
                      },
                      child: Material(
                        // ここでMaterialをラップ
                        color: Colors.transparent, // 必要に応じて透明でもOK
                        child: Container(
                          height: 200, // グラフの高さを調整
                          child: BarChart(
                            BarChartData(
                              maxY: 720, // 12時間（720分）を最大値に設定
                              barGroups: snapshot.data!,
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget:
                                        (double value, TitleMeta meta) {
                                      DateTime date =
                                          DateTime.fromMillisecondsSinceEpoch(
                                              value.toInt());
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          "${date.month}/${date.day}",
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 180,
                                    getTitlesWidget:
                                        (double value, TitleMeta meta) {
                                      switch (value.toInt()) {
                                        case 180:
                                          return Text('3h',
                                              style: TextStyle(fontSize: 12));
                                        case 360:
                                          return Text('6h',
                                              style: TextStyle(fontSize: 12));
                                        case 540:
                                          return Text('9h',
                                              style: TextStyle(fontSize: 12));
                                        case 720:
                                          return Text('12h',
                                              style: TextStyle(fontSize: 12));
                                        default:
                                          return Text('');
                                      }
                                    },
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 180, // 3時間ごとに水平線を表示
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: Colors.grey,
                                    strokeWidth: 0.5, // ラインの幅を縮小
                                  );
                                },
                              ),
                              barTouchData: BarTouchData(
                                touchTooltipData: BarTouchTooltipData(
                                  tooltipMargin: 4,
                                  tooltipPadding: EdgeInsets.all(4),
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                    DateTime date =
                                        DateTime.fromMillisecondsSinceEpoch(
                                            group.x.toInt());
                                    return BarTooltipItem(
                                      "${date.month}/${date.day}\n",
                                      TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: _convertToHoursAndMinutes(
                                              rod.toY),
                                          style: TextStyle(
                                              color: Colors.yellow,
                                              fontSize: 12),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                enabled: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 20),
          _buildCountdownSection(),
        ],
      ),
    );
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Widget _buildCountdownSection() {
    String countdownText = "設定されていません";

    if (targetDate != null) {
      Duration difference = targetDate!.difference(DateTime.now());
      countdownText = "${difference.inDays}日";
    }

    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: Column(
        children: [
          Text(
            "イベントまでのカウントダウン",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            countdownText,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _selectDate(context),
            child: Text('イベントの日付を設定'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: targetDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != targetDate) {
      setState(() {
        targetDate = picked;
      });
    }
  }

  Stream<double> _getTodayStudyTimeStream() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(0.0); // ユーザーがログインしていない場合は0を返す
    }

    DateTime now = DateTime.now();
    String today = DateFormat('yyyy-MM-dd').format(now);

    return FirebaseFirestore.instance
        .collectionGroup('studyLogs')
        .snapshots()
        .map((snapshot) {
      double todayStudyTime = 0;

      for (var logDoc in snapshot.docs) {
        String date = logDoc['date'];
        double studyTime = logDoc['studyTime'].toDouble();
        String? uid = logDoc['uid']; // uidがnullの可能性を考慮して?を付ける

        // 今日の日付と一致し、かつuidがnullでなく、現在のユーザーと一致する場合に勉強時間を加算
        if (date == today && uid != null && uid == user.uid) {
          todayStudyTime += studyTime;
        }
      }

      return todayStudyTime;
    });
  }

  Stream<double> _getThisMonthStudyTimeStream() {
    DateTime now = DateTime.now();
    String thisMonth = DateFormat('yyyy-MM').format(now);

    // 現在のユーザーのUIDを取得
    User? user = _auth.currentUser;
    if (user == null) {
      return Stream.value(0.0); // ユーザーが存在しない場合は 0.0 を返す
    }

    String uid = user.uid;

    return _firestore.collectionGroup('studyLogs').snapshots().map((snapshot) {
      double thisMonthStudyTime = 0;

      for (var logDoc in snapshot.docs) {
        String logUid = logDoc['uid']; // logDocからUIDを取得
        String date = logDoc['date'];
        double studyTime = logDoc['studyTime'].toDouble();

        // 現在のユーザーのUIDと一致するか確認し、かつ今月のデータであるか確認
        if (logUid == uid && date.startsWith(thisMonth)) {
          thisMonthStudyTime += studyTime;
        }
      }

      return thisMonthStudyTime;
    });
  }

  Stream<double> _getTotalStudyTimeStream() {
    // 現在のユーザーのUIDを取得
    User? user = _auth.currentUser;
    if (user == null) {
      return Stream.value(0.0); // ユーザーが存在しない場合は 0.0 を返す
    }

    String uid = user.uid;

    return _firestore.collectionGroup('studyLogs').snapshots().map((snapshot) {
      double totalStudyTime = 0;

      for (var logDoc in snapshot.docs) {
        String logUid = logDoc['uid']; // logDocからUIDを取得
        double studyTime = logDoc['studyTime'].toDouble();

        // 現在のユーザーのUIDと一致する場合のみ集計
        if (logUid == uid) {
          totalStudyTime += studyTime;
        }
      }

      return totalStudyTime;
    });
  }

  // // Firestoreから教材のカラーを取得する関数
  // Future<Color?> _getSubjectColor(String subjectId) async {
  //   try {
  //     var subjectDoc =
  //         await _firestore.collection('subjects').doc(subjectId).get();
  //     if (subjectDoc.exists) {
  //       var colorValue = subjectDoc.data()?['color'] as int?;
  //       if (colorValue != null) {
  //         print('カラー取得成功: $colorValue');
  //         return Color(colorValue); // カラーをColorクラスに変換して返す
  //       } else {
  //         print('カラーが存在しません');
  //         return Colors.grey; // カラーがない場合はデフォルトでグレーを返す
  //       }
  //     } else {
  //       print('ドキュメントが存在しません');
  //       return Colors.grey; // ドキュメントが存在しない場合もデフォルトでグレーを返す
  //     }
  //   } catch (e) {
  //     print('エラー: $e');
  //     return Colors.grey; // エラー時もデフォルトでグレーを返す
  //   }
  // }

  Stream<List<BarChartGroupData>> _getBarChartStream() {
    DateTime now = DateTime.now();
    DateTime startDate = now.subtract(Duration(days: 6)); // 過去7日間を取得
    User? user = _auth.currentUser;
    String uid = user?.uid ?? ''; // UIDが取得できなかった場合の対策も含める

    return _firestore
        .collectionGroup('studyLogs')
        .snapshots()
        .asyncMap((snapshot) async {
      Map<String, double> dailyStudyTime = {}; // 日付ごとの総勉強時間を保存

      // すべての学習ログを走査し、日付ごとの総学習時間を集計
      for (var logDoc in snapshot.docs) {
        String date = logDoc['date']; // 日付
        double studyTime = logDoc['studyTime'].toDouble(); // 勉強時間
        String logUid = logDoc['uid']; //各ログのUIDを取得
        // UIDが一致する場合のみ勉強時間を集計
        if (logUid == uid) {
          // 日付ごとの勉強時間を集計
          if (!dailyStudyTime.containsKey(date)) {
            dailyStudyTime[date] = 0.0;
          }
          dailyStudyTime[date] =
              dailyStudyTime[date]! + studyTime; // 日付ごとの勉強時間を加算
        }
      }

      // グラフのデータを生成
      List<BarChartGroupData> barGroups = [];

      for (int i = 0; i < 7; i++) {
        DateTime date = startDate.add(Duration(days: i));
        String dateString = DateFormat('yyyy-MM-dd').format(date); // 日付のフォーマット

        // その日の合計勉強時間を取得、ない場合は0
        double totalStudyTime = dailyStudyTime[dateString] ?? 0.0;
        int timestamp = date.millisecondsSinceEpoch; // 日付をUNIXタイムスタンプに変換

        // 1本の棒グラフとして追加
        barGroups.add(
          BarChartGroupData(
            x: timestamp, // X軸の位置を日付に対応
            barRods: [
              BarChartRodData(
                toY: totalStudyTime, // 合計勉強時間をY軸に反映
                width: 22,
                borderRadius: BorderRadius.circular(4), // 必要に応じて角を丸める
                color: Colors.blue, // 色を指定
              ),
            ],
          ),
        );
      }

      return barGroups;
    });
  }

// materialIdからsubjectIdを取得する関数
  Future<String?> _getSubjectIdFromMaterial(String materialId) async {
    try {
      // subjects コレクションから全ての subject を取得
      QuerySnapshot subjectsSnapshot =
          await _firestore.collection('subjects').get();

      // 各 subject ドキュメントを走査し、該当する materialId を探す
      for (var subjectDoc in subjectsSnapshot.docs) {
        DocumentSnapshot materialDoc = await subjectDoc.reference
            .collection('materials')
            .doc(materialId)
            .get();

        // materialId が存在すれば、その subjectId を返す
        if (materialDoc.exists) {
          return subjectDoc.id;
        }
      }
      return null; // 見つからなければ null を返す
    } catch (e) {
      print('エラー: $e');
      return null;
    }
  }

// subjectIdからcolorフィールドを取得する関数
  Future<Color?> _getSubjectColor(String subjectId) async {
    try {
      var subjectDoc =
          await _firestore.collection('subjects').doc(subjectId).get();
      if (subjectDoc.exists) {
        var colorValue = subjectDoc.data()?['color'] as int?;
        if (colorValue != null) {
          return Color(colorValue); // カラーをColorクラスに変換して返す
        } else {
          return Colors.grey; // カラーがない場合はデフォルトでグレーを返す
        }
      } else {
        return Colors.grey; // ドキュメントが存在しない場合もデフォルトでグレーを返す
      }
    } catch (e) {
      print('エラー: $e');
      return Colors.grey; // エラー時もデフォルトでグレーを返す
    }
  }

  Future<String?> _getMaterialName(String materialId) async {
    try {
      print(
          'Fetching material name for materialId: $materialId'); // デバッグ用のprint
      var materialDoc =
          await _firestore.collection('materials').doc(materialId).get();
      if (materialDoc.exists) {
        String? title = materialDoc.data()?['title'] as String?;
        print('Material title fetched: $title'); // 教材名が取得できたか確認
        return title;
      } else {
        print('Material not found for materialId: $materialId'); // 教材が見つからない場合
      }
    } catch (e) {
      print('Error fetching material: $e'); // エラーが発生した場合
    }
    return null;
  }

  Widget _buildStudyTimeHeaderCell(String title) {
    return Center(
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStudyTimeDataCell(double studyTime) {
    String formattedTime = _convertToHoursAndMinutes(studyTime);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: formattedTime.split("分").map((line) {
          return Text(
            line.isNotEmpty ? "$line分" : line,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          );
        }).toList(),
      ),
    );
  }

  String _convertToHoursAndMinutes(double minutes) {
    int hours = minutes ~/ 60;
    int remainingMinutes = (minutes % 60).toInt();
    return "${hours}時間${remainingMinutes}";
  }
}

// class SecondPage extends StatefulWidget {
//   @override
//   _SecondPageState createState() => _SecondPageState();
// }

// class _SecondPageState extends State<SecondPage> {
//   String message = '円グラフの詳細';

//   // メッセージを更新するメソッド
//   void updateMessage() {
//     setState(() {
//       message = 'メッセージが変更されました！';
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('別のページ'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               message,
//               style: TextStyle(fontSize: 24),
//             ),
//             SizedBox(height: 20), // 間隔を空けるためのウィジェット
//             ElevatedButton(
//               onPressed: updateMessage, // ボタンを押した時にメッセージを更新
//               child: Text('メッセージを変更'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class SecondPage extends StatefulWidget {
//   @override
//   _SecondPageState createState() => _SecondPageState();
// }

// class _SecondPageState extends State<SecondPage> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   Map<String, Map<String, double>> subjectStudyTime = {}; // 日付ごとの科目別勉強時間を保存
//   List<String> sortedDates = []; // 日付をソートして格納するリスト

class SecondPage extends StatefulWidget {
  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  Map<String, Map<String, Map<String, dynamic>>> studyDataByDate = {};

  @override
  void initState() {
    super.initState();
    fetchStudyData();
  }

  Future<void> fetchStudyData() async {
    // Firebaseからデータを取得
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    User? user = FirebaseAuth.instance.currentUser; // 現在のユーザーを取得
    if (user == null) {
      print('ログインしているユーザーがいません');
      return; // ユーザーがいない場合は処理を終了
    }
    String uid = user.uid; // 現在のユーザーのUIDを取得

    QuerySnapshot snapshot = await firestore.collection('subjects').get();

    Map<String, Map<String, Map<String, dynamic>>> tempData = {};

    for (var doc in snapshot.docs) {
      String subjectName = doc['name'];
      int colorValue = doc['color']; // Firestoreのcolorフィールドを取得
      Color subjectColor = Color(colorValue); // Colorオブジェクトに変換

      // 各サブコレクションからstudyLogsを取得
      QuerySnapshot materialsSnapshot =
          await doc.reference.collection('materials').get();
      for (var materialDoc in materialsSnapshot.docs) {
        QuerySnapshot studyLogsSnapshot =
            await materialDoc.reference.collection('studyLogs').get();
        for (var logDoc in studyLogsSnapshot.docs) {
          String date = logDoc['date']; // 日付
          double studyTime = logDoc['studyTime']; // 勉強時間
          String logUid = logDoc['uid']; // UIDを取得

          // UIDが現在のユーザーのUIDと一致する場合のみ処理を行う
          if (logUid == uid) {
            // 日付ごとの勉強時間を集計
            if (!tempData.containsKey(date)) {
              tempData[date] = {}; // 日付が存在しない場合は初期化
            }

            if (!tempData[date]!.containsKey(subjectName)) {
              tempData[date]![subjectName] = {
                'studyTime': 0.0,
                'color': subjectColor // 初期値と色を設定
              };
            }

            // 勉強時間を追加
            tempData[date]![subjectName]!['studyTime'] += studyTime;
          }
        }
      }
    }

    setState(() {
      studyDataByDate = tempData;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 日付順にソート
    List<String> sortedDates = studyDataByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(title: Text('日にちごとの勉強時間')),
      body: studyDataByDate.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                String date = sortedDates[index];
                Map<String, Map<String, dynamic>> subjectData =
                    studyDataByDate[date]!;
                double totalStudyTime = subjectData.values
                    .fold(0, (sum, data) => sum + data['studyTime']); // 合計時間を計算

                return Column(
                  children: [
                    Text(
                      date, // 日付を表示
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '合計勉強時間: ${totalStudyTime.toStringAsFixed(0)}分', // 合計時間を表示
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    SizedBox(
                        height: 200,
                        child: PieChart(createPieChartData(subjectData))),
                    SizedBox(height: 20), // スペース
                  ],
                );
              },
            ),
    );
  }

  PieChartData createPieChartData(
      Map<String, Map<String, dynamic>> subjectData) {
    return PieChartData(
      sections: subjectData.entries.map((entry) {
        double studyTime = entry.value['studyTime']; // 勉強時間
        Color color = entry.value['color']; // Firestoreから取得した色

        return PieChartSectionData(
          color: color, // Firestoreから取得した色を使用
          value: studyTime,
          title:
              '${entry.key}\n${studyTime.toStringAsFixed(0)}分', // 科目名と勉強時間を表示
          radius: 100,
          titleStyle: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        );
      }).toList(),
    );
  }

  // Firestoreの色情報を使うためにこのメソッドは不要
  // Color getColorForSubject(String subject) {
  //   // 科目に応じた色を返す（適当に設定）
  //   switch (subject) {
  //     case '理科':
  //       return Colors.blue;
  //     case '数学':
  //       return Colors.green;
  //     case '国語':
  //       return Colors.red;
  //     default:
  //       return Colors.grey;
  //   }
  // }
}
