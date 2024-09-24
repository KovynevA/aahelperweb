import 'package:aahelper/helper/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FindPage extends StatefulWidget {
  const FindPage({super.key});

  @override
  State<FindPage> createState() => _FindPageState();
}


class _FindPageState extends State<FindPage> {


  @override
  void initState() {
searchGroup();
    super.initState();
  }

  void searchGroup() async {
    await GroupsAA.searchGroups(name: 'Вешняки', metro: 'Выхино').then((value) => print(value.first));
  }

 


  @override
  Widget build(BuildContext context) {
   // searchGroups(name: 'Вешняки', metro: 'Выхино');
    return const Placeholder();
  }
}
