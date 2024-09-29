import 'package:aahelper/helper/stylemenu.dart';
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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
            child: Text(
          'Поиск по:',
          style: AppTextStyle.menutextstyle,
        )),
        GroupSearchScreen(),
      ],
    );
  }
}

class GroupSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<GroupsAA>> searchGroupsByMetro(String metro) async {
    QuerySnapshot querySnapshot =
        await _firestore.collection('allgroups').get();

    List<GroupsAA> groups = [];

    for (var doc in querySnapshot.docs) {
      var groupInfoDoc =
          await doc.reference.collection('groupInfo').doc('info').get();
      if (groupInfoDoc.exists) {
        var data = groupInfoDoc.data();
        if (data?['metro'] == metro) {
          groups.add(GroupsAA.fromJson(data as Map<String, dynamic>));
        }
      }
    }

    return groups;
  }
}

class GroupSearchScreen extends StatefulWidget {
  @override
  State<GroupSearchScreen> createState() => _GroupSearchScreenState();
}

class _GroupSearchScreenState extends State<GroupSearchScreen> {
  final GroupSearchService groupSearchService = GroupSearchService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController metroController = TextEditingController();
  final TextEditingController adressController = TextEditingController();
  final TextEditingController timeController = TextEditingController();

  final String metro = 'Выхино';

  @override
  void initState() {
    super.initState();
  }

  String _formatTiming(List<Map<String, String>>? timing) {
    if (timing != null && timing.isNotEmpty) {
      String result = '';
      for (var item in timing) {
        result += '${item.values.last}: ${item.values.first}\n';
      }
      return result;
    }
    return 'Не указано';
  }

  @override
  void dispose() {
    nameController.dispose();
    areaController.dispose();
    metroController.dispose();
    adressController.dispose();
    timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            AnimatedTextAndTextFieldWidget(
                text: 'По имени', controller: nameController),
            AnimatedTextAndTextFieldWidget(
                text: 'По району', controller: areaController),
            AnimatedTextAndTextFieldWidget(
                text: 'По метро', controller: metroController),
            AnimatedTextAndTextFieldWidget(
                text: 'По адресу', controller: adressController),
            AnimatedTextAndTextFieldWidget(
                text: 'По времени', controller: timeController),
            FutureBuilder<List<GroupsAA>>(
              future: groupSearchService.searchGroupsByMetro(metro),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Ошибка: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Нет данных'));
                } else {
                  List<GroupsAA> groups = snapshot.data!;
                  return Container(
                    height: 100.0 * groups.length,
                    width: MediaQuery.of(context).size.width - 30,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(colors: [
                        AppColor.backgroundColor,
                        AppColor.defaultColor
                      ]),
                      border: Border.all(
                          width: 6.0,
                          color: const Color.fromARGB(94, 225, 218, 245)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey,
                            offset: Offset(2, 1),
                            spreadRadius: 3,
                            blurRadius: 30)
                      ],
                    ),
                    child: ListView.builder(
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                            groups[index].name,
                            style: AppTextStyle.valuesstyle,
                          ),
                          subtitle: Column(
                            children: [
                              Text(
                                'Адрес: ${groups[index].adress}',
                                style: AppTextStyle.spantextstyle,
                              ),
                              Text(
                                'Время работы: ${_formatTiming(groups[index].timing)}',
                                style: AppTextStyle.minimalsstyle,
                              ),
                            ],
                          ),
                          // Здесь можно отображать другие данные группы
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
