import 'package:aahelper/service/leading/clockpicker/clockstyle.dart';
import 'package:flutter/material.dart';

class MyHours extends StatelessWidget {
  const MyHours({super.key, required this.hours});
  final int hours;

  @override
  Widget build(BuildContext context) {

    return ClockContainer(time: hours.toString());
  }
}
