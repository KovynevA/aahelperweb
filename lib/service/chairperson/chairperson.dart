import 'package:aahelper/service/chairperson/adminpanel.dart';
import 'package:aahelper/service/chairperson/servicetab.dart';
import 'package:aahelper/service/chairperson/workstab.dart';
import 'package:aahelper/helper/stylemenu.dart';
import 'package:aahelper/service/chairperson/settingsgroup.dart';
import 'package:flutter/material.dart';

// Общий виджет Председатель
class Chairman extends StatefulWidget {
  final String title;

  const Chairman({super.key, required this.title});

  @override
  State<Chairman> createState() => _ChairmanState();
}

class _ChairmanState extends State<Chairman>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> tabname = ['Рабочка', 'Служения', 'Группа', 'Права'];

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
          Center(
            child: WorksWidget(),
          ),
          CardsOfService(),
          SettingsGroup(),
          AdminPanel(),
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
