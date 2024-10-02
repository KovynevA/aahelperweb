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

// Поиск по имени
  Future<List<GroupsAA>> searchGroupByName(String name) async {
    List<GroupsAA> groups = [];
    var groupDoc = await _firestore.collection('allgroups').doc(name).get();
    if (groupDoc.exists) {
      var groupInfoDoc =
          await groupDoc.reference.collection('groupInfo').doc('info').get();
      if (groupInfoDoc.exists) {
        var data = groupInfoDoc.data();
        groups.add(GroupsAA.fromJson(data as Map<String, dynamic>));
      }
    }
    return groups;
  }

  // Поиск по району
  Future<List<GroupsAA>> searchGroupsByArea(String area) async {
    QuerySnapshot querySnapshot =
        await _firestore.collection('allgroups').get();

    List<GroupsAA> groups = [];

    for (var doc in querySnapshot.docs) {
      var groupInfoDoc =
          await doc.reference.collection('groupInfo').doc('info').get();
      if (groupInfoDoc.exists) {
        var data = groupInfoDoc.data();
        if (data?['area'] == area) {
          groups.add(GroupsAA.fromJson(data as Map<String, dynamic>));
        }
      }
    }
    return groups;
  }

// Поиск по метро
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

  // Фильтр по...
  Future<List<GroupsAA>> filterGroups(String prefix, String filter) async {
    List<GroupsAA> groups = [];
    QuerySnapshot querySnapshot =
        await _firestore.collection('allgroups').get();

    for (var doc in querySnapshot.docs) {
      var groupInfoQuerySnapshot = await doc.reference
          .collection('groupInfo')
          .where(filter,
              isGreaterThanOrEqualTo:
                  prefix) // Имя должно быть больше или равно префиксу
          .where(filter,
              isLessThan: getNextCharacter(
                  prefix)) // Имя должно быть меньше, чем следующий символ после префикса в алфавитном порядке
          .get();

      for (var groupInfoDoc in groupInfoQuerySnapshot.docs) {
        var data = groupInfoDoc.data();
        if (data[filter]
            .toString()
            .toLowerCase()
            .startsWith(prefix.toLowerCase())) {
          groups.add(GroupsAA.fromJson(data));
        }
      }
    }

    return groups;
  }

  // Вспомогательная функция для получения следующего символа в алфавите
  String getNextCharacter(String input) {
    if (input.isEmpty) {
      return 'я'; // Если ввод пустой, возвращаем последний символ в русском алфавите
    }
    final lastChar = input.runes.last;
    if (lastChar == 1105) {
      return String.fromCharCode(
          1025); // Если последний символ - "е", возвращаем "ё"
    } else if (lastChar == 1071) {
      return String.fromCharCode(
          1072); // Если последний символ - "я", возвращаем "а"
    } else {
      return String.fromCharCode(lastChar +
          1); // В остальных случаях возвращаем следующий символ в алфавите
    }
  }

// Вычленить время в мапе найденной группы
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
}

class GroupSearchScreen extends StatefulWidget {
  @override
  State<GroupSearchScreen> createState() => _GroupSearchScreenState();
}

class _GroupSearchScreenState extends State<GroupSearchScreen> {
  final GroupSearchService groupSearchService = GroupSearchService();
  final TextEditingController findController = TextEditingController();

  static const List<String> list = <String>[
    'Имени',
    'Району',
    'Метро',
    'Адресу',
  ];
  String dropdownValue = list.first;

  @override
  void initState() {
    //findController.text = '';
    super.initState();
  }

  @override
  void dispose() {
    findController.dispose();
    super.dispose();
  }

  Future<List<GroupsAA>> selectedFindFunction(String selectedFindValue) {
    if (selectedFindValue == list[0]) {
      return groupSearchService.filterGroups(findController.text, 'name');
    } else if (selectedFindValue == list[1]) {
      return groupSearchService.filterGroups(findController.text, 'area');
    } else if (selectedFindValue == list[2]) {
      return groupSearchService.filterGroups(findController.text, 'metro');
    } else
      return groupSearchService.filterGroups(findController.text, 'adress');
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.35,
                    height: 50,
                    decoration: BoxDecoration(
                        color: AppColor.backgroundColor,
                        border: Border.all(color: Colors.brown, width: 3),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                              color: Color.fromRGBO(
                                  0, 0, 0, 0.57), //shadow for button
                              blurRadius: 5) //blur radius of shadow
                        ]),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        icon: Icon(Icons.arrow_circle_down_sharp),
                        value: dropdownValue,
                        onChanged: (String? value) {
                          setState(() {
                            dropdownValue = value!;
                          });
                        },
                        items:
                            list.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: AppTextStyle.valuesstyle,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  TextFieldStyleWidget(
                    controller: findController,
                    sizewidth: MediaQuery.of(context).size.width * 0.5,
                    sizeheight: 50,
                    decoration: Decor.decorTextField,
                    onChanged: (String value) {
                      setState(() {
                        findController.text = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            findController.text != ''
                ? FutureBuilder<List<GroupsAA>>(
                    future: selectedFindFunction(dropdownValue),
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
                                      'Время работы: ${groupSearchService._formatTiming(groups[index].timing)}',
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
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
