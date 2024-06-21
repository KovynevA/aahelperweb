import 'package:aahelper/helper/stylemenu.dart';
import 'package:aahelper/service/treasurer/profit.dart';
import 'package:aahelper/service/treasurer/total.dart';
import 'package:aahelper/service/treasurer/workmeeting.dart';
import 'package:flutter/material.dart';

class Treasurer extends StatefulWidget {
  final String title;

  const Treasurer({super.key, required this.title});

  @override
  State<Treasurer> createState() => _TreasurerState();
}

class _TreasurerState extends State<Treasurer>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> tabname = ['Доход/расход', 'Итог', 'Рабочка'];

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
          Profit(),
          Total(),
          WorkMeeting(),
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
