import 'package:aahelper/service/leading/textpreample.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PreamblePage extends StatefulWidget {
  const PreamblePage({super.key});

  @override
  State<PreamblePage> createState() => _PreamblePageState();
}

class _PreamblePageState extends State<PreamblePage> {
  String? namegroup;
  String? nameleading;

  @override
  void initState() {
    super.initState();
    loadSavedValues();
  }

  void loadSavedValues() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('names_group_and_leading')
          .doc('data')
          .get();

      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

        namegroup = data['namegroup'];
        nameleading = data['nameleading'];
      } else {
        namegroup = '';
        nameleading = '';
      }
    } catch (e) {
      debugPrint('Ошибка загрузки данных из Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: TextPreamble(
          namegroup: namegroup ?? '',
          nameleading: nameleading ?? '',
        ),
      ),
    );
  }
}
