import 'package:aahelper/helper/stylemenu.dart';
import 'package:aahelper/service/calendar/calendar.dart';
import 'package:aahelper/service/chairperson/chairperson.dart';
import 'package:aahelper/service/findgroup/findgroup.dart';
import 'package:aahelper/service/leading/leading.dart';
import 'package:aahelper/service/librarian/librarian.dart';
import 'package:aahelper/service/speaker/speaker.dart';
import 'package:aahelper/service/servicewidget.dart';
import 'package:aahelper/service/tea/tea.dart';
import 'package:aahelper/service/treasurer/treasurer.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  void updateState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        title: const Text(
          'Помощник по служениям',
          style: AppTextStyle.menutextstyle,
        ),
      ),
      drawer: Drawer(
        backgroundColor: AppColor.backgroundColor,
        width: MediaQuery.of(context).size.width * 0.47,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.13,
              child: const DrawerHeader(
                curve: Curves.decelerate,
                decoration: BoxDecoration(
                  color: Colors.lightBlueAccent,
                ),
                child: Text(
                  'Меню',
                  style: AppTextStyle.menutextstyle,
                ),
              ),
            ),
            const TabBarPage(tabWidget: Chairman(title: 'Председатель')),
            const TabBarPage(tabWidget: Treasurer(title: 'Казначей')),
            const TabBarPage(tabWidget: Leading(title: 'Ведущий')),
            const TabBarPage(tabWidget: Speaker(title: 'Спикерхантер')),
            const TabBarPage(tabWidget: Librarian(title: 'Библиотекарь')),
            const TabBarPage(tabWidget: TeaMan(title: 'Чайханщик')),
           // const TabBarPage(tabWidget: FindGroup(title: 'Найти группу')),
          ],
        ),
      ),
      body: ChairEventCalendar(
        updateStateCalendar: updateState,
      ),
      backgroundColor: AppColor.backgroundColor,
    );
  }
}
