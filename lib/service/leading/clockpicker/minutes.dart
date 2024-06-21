import 'package:aahelper/service/leading/clockpicker/clockstyle.dart';
import 'package:flutter/material.dart';

class MyMinutes extends StatelessWidget {
  const MyMinutes({super.key, required this.mins});
  final int mins;

  @override
  Widget build(BuildContext context) {
    String time = '00';
    mins < 10 ? time = '0$mins' : time = mins.toString();
    return ClockContainer(
      time: time,
    );
  }
}
