import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PageFour extends StatefulWidget {
  @override
  _PageFourState createState() => _PageFourState();
}

class _PageFourState extends State<PageFour> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
          Expanded(
            child: StreamBuilder<List<BarChartGroupData>>(
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0), // 横のパディングを調整
                  child: Column(
                    children: [
                      // Table(
                      //   columnWidths: const <int, TableColumnWidth>{
                      //     0: FlexColumnWidth(1),
                      //     1: FlexColumnWidth(1),
                      //     2: FlexColumnWidth(1),
                      //   },
                      //   children: [
                      //     TableRow(
                      //       children: [
                      //         _buildStudyTimeHeaderCell("今日"),
                      //         _buildStudyTimeHeaderCell("今月"),
                      //         _buildStudyTimeHeaderCell("総計"),
                      //       ],
                      //     ),
                      //     TableRow(
                      //       children: [
                      //         StreamBuilder<double>(
                      //           stream: _getTodayStudyTimeStream(),
                      //           builder: (context, snapshot) {
                      //             if (!snapshot.hasData) {
                      //               return _buildStudyTimeDataCell(0);
                      //             }
                      //             return _buildStudyTimeDataCell(
                      //                 snapshot.data!);
                      //           },
                      //         ),
                      //         StreamBuilder<double>(
                      //           stream: _getThisMonthStudyTimeStream(),
                      //           builder: (context, snapshot) {
                      //             if (!snapshot.hasData) {
                      //               return _buildStudyTimeDataCell(0);
                      //             }
                      //             return _buildStudyTimeDataCell(
                      //                 snapshot.data!);
                      //           },
                      //         ),
                      //         StreamBuilder<double>(
                      //           stream: _getTotalStudyTimeStream(),
                      //           builder: (context, snapshot) {
                      //             if (!snapshot.hasData) {
                      //               return _buildStudyTimeDataCell(0);
                      //             }
                      //             return _buildStudyTimeDataCell(
                      //                 snapshot.data!);
                      //           },
                      //         ),
                      //       ],
                      //     ),
                      //   ],
                      // ),
                      SizedBox(height: 20), // 上の表とのスペースを追加
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
                                        text:
                                            _convertToHoursAndMinutes(rod.toY),
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
          ),
        ],
      ),
    );
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

  Stream<List<BarChartGroupData>> _getBarChartStream() {
    DateTime now = DateTime.now();
    DateTime startDate = now.subtract(Duration(days: 6)); // 過去7日間を取得

    return _firestore.collectionGroup('studyLogs').snapshots().map((snapshot) {
      Map<String, double> dailyStudyTime = {};

      for (var logDoc in snapshot.docs) {
        String date = logDoc['date'];
        double studyTime = logDoc['studyTime'].toDouble();

        // 過去7日間のデータを対象にフィルタリング
        DateTime logDate = DateTime.parse(date);
        if (logDate.isAfter(startDate) &&
            logDate.isBefore(now.add(Duration(days: 1)))) {
          if (dailyStudyTime.containsKey(date)) {
            dailyStudyTime[date] = dailyStudyTime[date]! + studyTime;
          } else {
            dailyStudyTime[date] = studyTime;
          }
        }
      }

      List<BarChartGroupData> barGroups = [];
      for (int i = 0; i < 7; i++) {
        DateTime date = startDate.add(Duration(days: i));
        String dateString = DateFormat('yyyy-MM-dd').format(date);
        double yValue = dailyStudyTime[dateString] ?? 0;

        barGroups.add(
          BarChartGroupData(
            x: date.millisecondsSinceEpoch,
            barRods: [
              BarChartRodData(
                toY: yValue,
                color: Colors.blueAccent,
                width: 22,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
      }

      return barGroups;
    });
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
