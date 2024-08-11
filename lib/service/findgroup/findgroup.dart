
import 'package:aahelper/helper/stylemenu.dart';
import 'package:aahelper/service/findgroup/findpage.dart';
import 'package:flutter/material.dart';

class FindGroup extends StatefulWidget {
  final String title;

  const FindGroup({super.key, required this.title});

  @override
  State<FindGroup> createState() => _FindGroupState();
}

class _FindGroupState extends State<FindGroup> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> tabname = ['Поиск'];

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
          FindPage(),
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
