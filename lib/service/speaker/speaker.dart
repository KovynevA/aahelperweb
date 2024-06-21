import 'package:aahelper/helper/stylemenu.dart';
import 'package:aahelper/service/speaker/speakercard.dart';
import 'package:flutter/material.dart';

class Speaker extends StatefulWidget {
  const Speaker({super.key, required this.title});

  final String title;

  @override
  State<Speaker> createState() => _SpeakerState();
}

class _SpeakerState extends State<Speaker> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        title: Text(widget.title),
      ),
      body: const Speakercard(),
    );
  }
}
