import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PageFour extends StatefulWidget {
  @override
  _PageFourState createState() => _PageFourState();
}

class _PageFourState extends State<PageFour> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String selectedSubjectId = 'your_subject_id_here'; // 適切なsubject IDに置き換え

  Future<List<FlSpot>> _getStudyTimeData() async {
    final QuerySnapshot snapshot = await _firestore
        .collection('subjects')
        .doc(selectedSubjectId)
        .collection('materials')
        .orderBy('createdAt')
        .get();

    List<FlSpot> spots = [];
    int index = 0;
    for (var doc in snapshot.docs) {
      double studyTime = doc['studyTime'];
      spots.add(FlSpot(index.toDouble(), studyTime));
      index++;
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Study Time Graph'),
      ),
      body: FutureBuilder<List<FlSpot>>(
        future: _getStudyTimeData(),
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
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: snapshot.data!,
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.lightBlueAccent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    barWidth: 3,
                    belowBarData: BarAreaData(show: false),
                    dotData: FlDotData(show: false),
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                ),
                borderData: FlBorderData(show: true),
                gridData: FlGridData(show: true),
              ),
            ),
          );
        },
      ),
    );
  }
}
