import 'package:aahelper/service/chairperson/chairperson.dart';
import 'package:aahelper/service/leading/leading.dart';
import 'package:aahelper/service/librarian/librarian.dart';
import 'package:aahelper/service/speaker/speaker.dart';
import 'package:aahelper/service/tea/tea.dart';
import 'package:aahelper/service/treasurer/treasurer.dart';
import 'package:aahelper/helper/stylemenu.dart';
import 'package:flutter/material.dart';

class TabBarPage extends StatelessWidget {
  final Widget tabWidget;

  const TabBarPage({
    super.key,
    required this.tabWidget,
  });

  @override
  Widget build(BuildContext context) {
    String title = '';
    if (tabWidget is Chairman) {
      title = (tabWidget as Chairman)
          .title; // Получаем параметр title из виджета Chairman
    }
    if (tabWidget is Leading) {
      title = (tabWidget as Leading)
          .title; // Получаем параметр title из виджета Leading
    }

    if (tabWidget is Treasurer) {
      title = (tabWidget as Treasurer)
          .title; // Получаем параметр title из виджета Treasurer
    }

    if (tabWidget is Speaker) {
      title = (tabWidget as Speaker)
          .title; // Получаем параметр title из виджета Speaker
    }

    if (tabWidget is Librarian) {
      title = (tabWidget as Librarian)
          .title; // Получаем параметр title из виджета Librarian
    }
    if (tabWidget is TeaMan) {
      title = (tabWidget as TeaMan)
          .title; // Получаем параметр title из виджета TeaMan
    }
    // if (tabWidget is FindGroup) {
    //   title = (tabWidget as FindGroup)
    //       .title; // Получаем параметр title из виджета TeaMan
    // }
    return ListTile(
      title: Text(
        title,
        style: AppTextStyle.menutextstyle,
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => tabWidget,
          ),
        );
      },
    );
  }
}
