import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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
                    Container(
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
                                    padding: const EdgeInsets.only(top: 8.0),
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
                              sideTitles: SideTitles(
                                showTitles: false, // Y軸の右側のラベルを非表示にする
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: false, // これにより上部のタイトルを非表示にする
                              ),
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
                              tooltipMargin: 4, // マージンを縮小
                              tooltipPadding: EdgeInsets.all(4), // パディングを縮小
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
                                      fontSize: 12), // フォントサイズを調整
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: _convertToHoursAndMinutes(rod.toY),
                                      style: TextStyle(
                                          color: Colors.yellow,
                                          fontSize: 12), // フォントサイズを調整
                                    ),
                                  ],
                                );
                              },
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
    DateTime now = DateTime.now();
    String today = DateFormat('yyyy-MM-dd').format(now);

    return _firestore.collectionGroup('studyLogs').snapshots().map((snapshot) {
      double todayStudyTime = 0;

      for (var logDoc in snapshot.docs) {
        String date = logDoc['date'];
        double studyTime = logDoc['studyTime'].toDouble();

        if (date == today) {
          todayStudyTime += studyTime;
        }
      }

      return todayStudyTime;
    });
  }

  Stream<double> _getThisMonthStudyTimeStream() {
    DateTime now = DateTime.now();
    String thisMonth = DateFormat('yyyy-MM').format(now);

    return _firestore.collectionGroup('studyLogs').snapshots().map((snapshot) {
      double thisMonthStudyTime = 0;

      for (var logDoc in snapshot.docs) {
        String date = logDoc['date'];
        double studyTime = logDoc['studyTime'].toDouble();

        if (date.startsWith(thisMonth)) {
          thisMonthStudyTime += studyTime;
        }
      }

      return thisMonthStudyTime;
    });
  }

  Stream<double> _getTotalStudyTimeStream() {
    return _firestore.collectionGroup('studyLogs').snapshots().map((snapshot) {
      double totalStudyTime = 0;

      for (var logDoc in snapshot.docs) {
        double studyTime = logDoc['studyTime'].toDouble();
        totalStudyTime += studyTime;
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

    return _firestore
        .collectionGroup('studyLogs')
        .snapshots()
        .asyncMap((snapshot) async {
      Map<String, Map<String, double>> dailyStudyTimeByMaterial =
          {}; // 教材別の学習時間を保存
      Set<String> materialIds = {}; // 全教材のIDを保持
      Map<String, Color?> materialColors = {}; // 教材ごとの色を保持

      // すべての学習ログを走査し、教材ごとの学習時間を日付別に集計
      for (var logDoc in snapshot.docs) {
        String date = logDoc['date']; // 日付
        String materialId = logDoc.reference.parent.parent!.id; // 教材のID
        double studyTime = logDoc['studyTime'].toDouble();
        final parentRef = logDoc.reference.parent.parent!;
        final parentDoc = await parentRef.get();
        print(parentDoc.get('title'));

        materialIds.add(materialId); // 教材IDを追加

        // ここで materialId から subjectId を取得し、subjectId に含まれる color を取得する
        if (!materialColors.containsKey(materialId)) {
          // materialId から subjectId を取得
          String? subjectId = await _getSubjectIdFromMaterial(materialId);

          if (subjectId != null) {
            // subjectId から color を取得
            Color? color = await _getSubjectColor(subjectId);
            materialColors[materialId] = color ?? Colors.grey;
          } else {
            materialColors[materialId] = Colors.grey; // subjectId が見つからない場合はグレー
          }
        }

        // 日付ごとの学習時間を集計
        if (!dailyStudyTimeByMaterial.containsKey(date)) {
          dailyStudyTimeByMaterial[date] = {};
        }
        dailyStudyTimeByMaterial[date]![materialId] =
            (dailyStudyTimeByMaterial[date]?[materialId] ?? 0.0) + studyTime;
      }

      // グラフのデータを生成
      List<BarChartGroupData> barGroups = [];

      for (int i = 0; i < 7; i++) {
        DateTime date = startDate.add(Duration(days: i));
        String dateString = DateFormat('yyyy-MM-dd').format(date); // 日付のフォーマット
        List<BarChartRodData> rods = [];

        if (dailyStudyTimeByMaterial.containsKey(dateString)) {
          double startY = 0;
          // 各教材ごとの棒グラフを作成
          materialIds.forEach((materialId) {
            double studyTime =
                dailyStudyTimeByMaterial[dateString]?[materialId] ?? 0.0;
            if (studyTime > 0) {
              rods.add(
                BarChartRodData(
                  toY: studyTime,
                  width: 22,
                  borderRadius: BorderRadius.circular(4),
                  color: materialColors[materialId] ?? Colors.grey, // カラーを適用
                ),
              );
            }
          });
        }

        // 棒グラフのグループを追加
        barGroups.add(
          BarChartGroupData(
            x: date.millisecondsSinceEpoch,
            barRods: rods,
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
