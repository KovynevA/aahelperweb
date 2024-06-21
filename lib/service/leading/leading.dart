import 'package:aahelper/helper/stylemenu.dart';
import 'package:aahelper/service/leading/preamble.dart';
import 'package:aahelper/service/leading/protocol.dart';
import 'package:aahelper/service/leading/reminders.dart';
import 'package:flutter/material.dart';

class Leading extends StatefulWidget {
  final String title;

  const Leading({super.key, required this.title});

  @override
  State<Leading> createState() => _LeadingState();
}

class _LeadingState extends State<Leading> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> tabname = ['Преамбула', 'Напоминания', 'Протокол'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabname.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        title: Text(widget.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: List.generate(
              _tabController.length, (index) => Tab(text: tabname[index])),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PreamblePage(),
          RemindersPage(),
          ProtocolPage(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    
    _tabController.dispose();
    super.dispose();
  }

}
