import 'package:aahelper/helper/stylemenu.dart';
import 'package:aahelper/helper/utils.dart';
import 'package:flutter/material.dart';

class FindPage extends StatelessWidget {
  const FindPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              'Поиск по:',
              style: AppTextStyle.menutextstyle,
            ),
          ),
        ),
        GroupSearchScreen(),
      ],
    );
  }
}

class GroupSearchScreen extends StatefulWidget {
  @override
  State<GroupSearchScreen> createState() => _GroupSearchScreenState();
}

class _GroupSearchScreenState extends State<GroupSearchScreen> {
  final GroupSearchService groupSearchService = GroupSearchService();
  final TextEditingController findController = TextEditingController();
  TimePeriod todayTime = TimePeriod.evening;
  bool isToday = true;
  List<GroupsAA> groups = [];
  String previousText = '';

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

  Future<List<GroupsAA>> selectedFindFunction(String selectedFindValue) async {
    List<GroupsAA> filterGroups = [];
    if (findController.text == '') {
      groups = [];
      filterGroups = [];
    }
    if (findController.text.isNotEmpty) {
      if (isAddingCharacter(findController.text, previousText)) {
        groups = groups;
      } else if (isRemovingOrChangingCharacter(
          findController.text, previousText)) {
        groups = [];
        filterGroups = [];
      }
      if (selectedFindValue == list[0]) {
        groups = await groupSearchService.filterGroups(
            findController.text, 'name', groups);
      } else if (selectedFindValue == list[1]) {
        groups = await groupSearchService.filterGroups(
            findController.text, 'area', groups);
      } else if (selectedFindValue == list[2]) {
        groups = await groupSearchService.filterGroups(
            findController.text, 'metro', groups);
      } else {
        groups = await groupSearchService.filterGroupsbyAdres(
            findController.text, 'adress', groups);
      }
    }
    if (groups != []) {
      filterGroups = await groupSearchService.filterGroupsByTime(
        todayTime,
        groups,
        isToday,
      ); // утро, день, вечер
    }
    previousText =
        findController.text; // Сохраняем текущий текст для следующего сравнения
    return filterGroups;
  }

  bool isAddingCharacter(String currentText, String previousText) {
    // Функция для проверки, был ли добавлен символ
    return currentText.length > previousText.length;
  }

  bool isRemovingOrChangingCharacter(String currentText, String previousText) {
    // Функция для проверки, был ли удален или изменен символ
    if (currentText.length < previousText.length) {
      return true; // Если длина текущего текста меньше предыдущего, символ был удален
    } else {
      // Проверяем каждый символ для определения, был ли изменен символ
      for (int i = 0; i < previousText.length; i++) {
        if (i >= currentText.length || currentText[i] != previousText[i]) {
          return true;
        }
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                          color:
                              Color.fromRGBO(0, 0, 0, 0.57), //shadow for button
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
                    items: list.map<DropdownMenuItem<String>>((String value) {
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'По времени:',
                style: AppTextStyle.menutextstyle,
              ),
              Row(
                children: [
                  Text(
                    'На сегодня',
                    style: AppTextStyle.spantextstyle,
                  ),
                  Checkbox(
                    value: isToday,
                    onChanged: (bool? newvalue) {
                      setState(() {
                        isToday = newvalue!;
                      });
                    },
                  ),
                ],
              )
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SegmentedButton<TimePeriod>(
            style: SegmentedButton.styleFrom(
              backgroundColor: AppColor.defaultColor,
              foregroundColor: Colors.red,
              selectedForegroundColor: Colors.white,
              selectedBackgroundColor: Colors.green,
            ),
            segments: <ButtonSegment<TimePeriod>>[
              ButtonSegment<TimePeriod>(
                value: TimePeriod.morning,
                label: Text(
                  'Утро',
                  style: AppTextStyle.valuesstyle,
                ),
                icon: Icon(Icons.sunny),
              ),
              ButtonSegment<TimePeriod>(
                value: TimePeriod.afternoon,
                label: Text(
                  'День',
                  style: AppTextStyle.valuesstyle,
                ),
                icon: Icon(Icons.lunch_dining),
              ),
              ButtonSegment<TimePeriod>(
                value: TimePeriod.evening,
                label: Text(
                  'Вечер',
                  style: AppTextStyle.valuesstyle,
                ),
                icon: Icon(Icons.bed),
              ),
            ],
            selected: <TimePeriod>{todayTime},
            onSelectionChanged: (Set<TimePeriod> newSelection) {
              setState(() {
                todayTime = newSelection.first;
              });
            },
          ),
        ),
        Container(
          margin: EdgeInsets.all(8.0),
          height: MediaQuery.of(context).size.height - 370,
          decoration: Decor.decorTextField,
          child: //findController.text != '' ?
              FutureBuilder<List<GroupsAA>>(
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
                return ListView.builder(
                  shrinkWrap: true,
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
                            'Время работы: ${groupSearchService.formatTiming(groups[index].timing)}',
                            style: AppTextStyle.minimalsstyle,
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
            },
          ),
          //  : Container(),
        ),
      ],
    );
  }
}
