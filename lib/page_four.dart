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

  double _todayStudyTime = 0;
  double _thisMonthStudyTime = 0;
  double _totalStudyTime = 0;

  @override
  void initState() {
    super.initState();
    _calculateStudyTimes();
  }

  Future<void> _calculateStudyTimes() async {
    DateTime now = DateTime.now();
    String today = DateFormat('yyyy-MM-dd').format(now);
    String thisMonth = DateFormat('yyyy-MM').format(now);

    double todayStudyTime = 0;
    double thisMonthStudyTime = 0;
    double totalStudyTime = 0;

    final QuerySnapshot subjectsSnapshot =
        await _firestore.collection('subjects').get();

    for (var subjectDoc in subjectsSnapshot.docs) {
      final QuerySnapshot materialsSnapshot =
          await subjectDoc.reference.collection('materials').get();

      for (var materialDoc in materialsSnapshot.docs) {
        final QuerySnapshot studyLogsSnapshot =
            await materialDoc.reference.collection('studyLogs').get();

        for (var logDoc in studyLogsSnapshot.docs) {
          String date = logDoc['date'];
          double studyTime = logDoc['studyTime'].toDouble();

          // 今日の勉強時間を集計
          if (date == today) {
            todayStudyTime += studyTime;
          }

          // 今月の勉強時間を集計
          if (date.startsWith(thisMonth)) {
            thisMonthStudyTime += studyTime;
          }

          // 総勉強時間を集計
          totalStudyTime += studyTime;
        }
      }
    }

    setState(() {
      _todayStudyTime = todayStudyTime;
      _thisMonthStudyTime = thisMonthStudyTime;
      _totalStudyTime = totalStudyTime;
    });
  }

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
                    _buildStudyTimeDataCell(_todayStudyTime),
                    _buildStudyTimeDataCell(_thisMonthStudyTime),
                    _buildStudyTimeDataCell(_totalStudyTime),
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
                  padding: const EdgeInsets.all(16.0),
                  child: AspectRatio(
                    aspectRatio: 1.7,
                    child: BarChart(
                      BarChartData(
                        maxY: 720, // 12時間（720分）を最大値に設定
                        barGroups: snapshot.data!,
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
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
                              getTitlesWidget: (double value, TitleMeta meta) {
                                switch (value.toInt()) {
                                  case 180:
                                    return Text('3時間',
                                        style: TextStyle(fontSize: 12));
                                  case 360:
                                    return Text('6時間',
                                        style: TextStyle(fontSize: 12));
                                  case 540:
                                    return Text('9時間',
                                        style: TextStyle(fontSize: 12));
                                  case 720:
                                    return Text('12時間',
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
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 180, // 3時間ごとに水平線を表示
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey,
                              strokeWidth: 1,
                            );
                          },
                        ),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            tooltipMargin: 8,
                            tooltipPadding: EdgeInsets.all(8),
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              DateTime date =
                                  DateTime.fromMillisecondsSinceEpoch(
                                      group.x.toInt());
                              return BarTooltipItem(
                                "${date.month}/${date.day}\n",
                                TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: _convertToHoursAndMinutes(rod.toY),
                                    style: TextStyle(
                                        color: Colors.yellow, fontSize: 14),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<BarChartGroupData>> _getBarChartStream() {
    return _firestore
        .collection('subjects')
        .snapshots()
        .asyncMap((subjectsSnapshot) async {
      Map<String, double> dailyStudyTime = {};

      for (var subjectDoc in subjectsSnapshot.docs) {
        final materialsSnapshot =
            await subjectDoc.reference.collection('materials').get();

        for (var materialDoc in materialsSnapshot.docs) {
          final studyLogsSnapshot =
              await materialDoc.reference.collection('studyLogs').get();

          for (var logDoc in studyLogsSnapshot.docs) {
            String date = logDoc['date'];
            double studyTime = logDoc['studyTime'].toDouble();

            if (dailyStudyTime.containsKey(date)) {
              dailyStudyTime[date] = dailyStudyTime[date]! + studyTime;
            } else {
              dailyStudyTime[date] = studyTime;
            }
          }
        }
      }

      List<BarChartGroupData> barGroups = [];
      List<String> sortedDates = dailyStudyTime.keys.toList()..sort();

      for (int index = 0; index < sortedDates.length; index++) {
        String date = sortedDates[index];
        DateTime dateTime = DateTime.parse(date);
        double yValue = dailyStudyTime[date]!;
        barGroups.add(
          BarChartGroupData(
            x: dateTime.millisecondsSinceEpoch,
            barRods: [
              BarChartRodData(
                toY: yValue,
                color: Colors.blueAccent,
                width: 22, // 棒の幅を設定
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
