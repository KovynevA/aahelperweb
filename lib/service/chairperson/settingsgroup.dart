// Настройки группы
import 'package:aahelper/helper/stylemenu.dart';
import 'package:aahelper/helper/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsGroup extends StatefulWidget {
  const SettingsGroup({
    super.key,
  });

  @override
  State<SettingsGroup> createState() => _SettingsGroupState();
}

class _SettingsGroupState extends State<SettingsGroup> {
  List<String> selectedDays = [];
  List<ProfitGroup> profitGroup = [];
  List<Deductions> listdeductions = [];
  List<ProtocolMeeting> listprotocolMeeting = [];

  int? numWeekOfMonth;
  int? numOfDay;
  int? dayOfMonth;

  WorkMeetingSchedule? workMeetingSchedule;

  bool numDayNumWeekCheckbox = true;
  bool numDayOfMonthCheckbox = false;
  ServiceUser? serviceUser;

  @override
  void initState() {
    getMeetingShedule();
    loadServiceuser();
    loadprofitGroup();
    super.initState();
  }

  void loadServiceuser() async {
    serviceUser = await getServiceUser();
  }

  void loadprofitGroup() async {
    profitGroup = await ProfitGroup.loadProfitGroups() ?? [];
  }

  void getMeetingShedule() async {
    workMeetingSchedule = await WorkMeetingSchedule.loadWorkMeetingSchedule();
    if (workMeetingSchedule != null) {
      setState(() {
        selectedDays = workMeetingSchedule?.selectedDays ?? [];
        numOfDay = workMeetingSchedule?.numOfDay;
        numWeekOfMonth = workMeetingSchedule?.numWeekOfMonth;
        dayOfMonth = workMeetingSchedule?.dayOfMonth;
        if (workMeetingSchedule!.checkboxstatus != null) {
          numDayNumWeekCheckbox = workMeetingSchedule!.checkboxstatus!;
          numDayOfMonthCheckbox = !workMeetingSchedule!.checkboxstatus!;
        }
      });
    } else {
      numWeekOfMonth = null;
      numOfDay = null;
      dayOfMonth = null;
      debugPrint('Расписание отсутствует');
    }
  }

  void updateState() async {
    loadServiceuser();
    getMeetingShedule();
    await Event.loadEventsFromFirestore(
        RepeatOptions('Не повторять', RepeatType.none));
  }

// В список событий добавить список ВСЕХ собраний группы и заполнить пустой лист
//всех собраний
  void addMeetingEvents() {
    loadprofitGroup();
    kEvents.clear();
    for (var day in selectedDays) {
      DateTime date = kFirstDay;
      while (date.isBefore(kLastDay)) {
        // Если индекс дня недели совпадает с номером дня недели из selectedDays
        if (date.weekday == Event.getWeekdayIndex(day)) {
          //Если на эту дату нет события Собрание группы
          if (!hasEventForDate(date, 'Собрание группы')) {
            kEvents.putIfAbsent(date, () => []).add(Event('Собрание группы',
                RepeatOptions('Еженедельно', RepeatType.weekly)));
          }
          if (!isDateAlreadyInProfitGroup(date)) {
            profitGroup.add(ProfitGroup(date: date));
          } // Добавляем только если нет события на эту дату

          if (!isDateAlreadyInProtocolMeeting(date)) {
            ServiceUser? user;
            currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser != null) {
              ServiceUser.getServiceUserFromFirestore(currentUser!.email!)
                  .then((onValue) {
                user = onValue;
              });
            }
            listprotocolMeeting.add(ProtocolMeeting(
              date: date,
              leadingName: user?.name ?? '',
              themeMeeting: [],
              waspresent: 0,
            ));
          } // Добавляем только если нет протокола на эту дату
        }
        date = date.add(const Duration(days: 1));
      }
    }

    // Не забудьте сортировать список после добавления новых элементов
    profitGroup.sort((a, b) => a.date.compareTo(b.date));
    listprotocolMeeting.sort((a, b) => a.date.compareTo(b.date));
    addEventsForWorksMeetings(); // Добавляем Новые Рабочие собрания
  }

  bool hasEventForDate(DateTime date, String eventName) {
    return kEvents[date]?.any((event) => event.title == eventName) ?? false;
  }

  //проверка совпадения даты в доходах
  bool isDateAlreadyInProfitGroup(DateTime date) {
    return profitGroup.any((element) => element.date.isAtSameMomentAs(date));
  }

  //проверка совпадения даты в протоколах собраний
  bool isDateAlreadyInProtocolMeeting(DateTime date) {
    return listprotocolMeeting.any(
      (element) => element.date.isAtSameMomentAs(date),
    );
  }

  // В список событий Добавить рабочие собрания и заполнить пустой лист всех
  //рабочих собраний
  void addEventsForWorksMeetings() {
    listdeductions.clear(); // Очищаем переменную
    // Если отчентный период по номеру дня и номеру недели
    if (numDayNumWeekCheckbox) {
      // Получаем номер недели в месяце и день недели текущей даты
      int weekNumber = workMeetingSchedule?.numWeekOfMonth ?? 1;
      int dayOfWeek = (workMeetingSchedule?.numOfDay ?? 1) + 1;
      // Логика для создания повторяющихся событий в каждом следующем месяце
      DateTime nextDate =
          kFirstDay.add(const Duration(days: 1)); // Начинаем с следующего дня
      while (nextDate.isBefore(kLastDay)) {
        // Особый случай - Если выбранная нелделя (numWeekOfMonth) "Последняя"
        if (weekNumber == 6) {
          if (nextDate.weekday == dayOfWeek &&
              (nextDate.month < nextDate.add(Duration(days: 7)).month ||
                  nextDate.add(Duration(days: 7)).year > nextDate.year)) {
            final eventsForNextDate = kEvents[nextDate] ?? <Event>[];
            eventsForNextDate.add(
              Event(
                'Рабочее собрание',
                RepeatOptions('Ежемесячно', RepeatType.monthly),
              ),
            );

            kEvents[nextDate] = List.from(eventsForNextDate);
            listdeductions.add(Deductions(date: nextDate));
          }
        } else {
          int nextWeekNumber = (nextDate.day + 6) ~/ 7;
          int nextDayOfWeek = nextDate.weekday;
          if (nextWeekNumber == weekNumber && nextDayOfWeek == dayOfWeek) {
            final eventsForNextDate = kEvents[nextDate] ?? <Event>[];
            eventsForNextDate.add(
              Event(
                'Рабочее собрание',
                RepeatOptions('Ежемесячно', RepeatType.monthly),
              ),
            );

            kEvents[nextDate] = List.from(eventsForNextDate);
            listdeductions.add(Deductions(date: nextDate));
          }
        }
        nextDate =
            nextDate.add(const Duration(days: 1)); // Переходим к следующему дню
      }
      // Если отчетный период 1 число месяца
    } else {
      DateTime nextDate =
          kFirstDay.add(const Duration(days: 1)); // Начинаем с следующего дня
      while (nextDate.isBefore(kLastDay)) {
        if (nextDate.day == dayOfMonth) {
          final eventsForNextDate = kEvents[nextDate] ?? <Event>[];
          eventsForNextDate.add(
            Event(
              'Рабочее собрание',
              RepeatOptions('Ежемесячно', RepeatType.monthly),
            ),
          );

          kEvents[nextDate] = List.from(eventsForNextDate);
          listdeductions.add(Deductions(date: nextDate));
        }
        nextDate = DateTime(nextDate.year, nextDate.month, nextDate.day + 1,
            1); // Переходим к следующему месяцу
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 10,
            ),
            const Padding(
              padding: EdgeInsets.all(10.0),
              child: Text(
                'Выберите расписание группы',
                style: AppTextStyle.menutextstyle,
              ),
            ),
            Center(
              child: Wrap(
                direction: Axis.horizontal,
                alignment: WrapAlignment.start,
                spacing: 8.0,
                runSpacing: 8.0,
                children: <Widget>[
                  for (var day in daysOfWeek)
                    FilterChip(
                      backgroundColor: AppColor.cardColor,
                      elevation: 8.0,
                      shadowColor: Colors.grey,
                      showCheckmark: false,
                      selectedColor: AppColor.deleteCardColor,
                      label: Text(
                        day,
                      ),
                      labelStyle: AppTextStyle.minimalsstyle,
                      labelPadding: const EdgeInsets.all(6),
                      selected: selectedDays.contains(day),
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            selectedDays.add(day);
                          } else {
                            selectedDays.remove(day);
                            Event.removeMeetingEvents(
                                day); // Удаляем события для этого дня
                          }
                        });
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            const Text(
              'Рабочее собрание:',
              style: AppTextStyle.menutextstyle,
            ),
            CheckboxListTile(
              value: numDayNumWeekCheckbox,
              onChanged: (value) {
                setState(() {
                  numDayNumWeekCheckbox = value!;
                  numDayOfMonthCheckbox = !numDayOfMonthCheckbox;
                  workMeetingSchedule?.checkboxstatus = numDayNumWeekCheckbox;
                });
              },
              title: WeekSelectorDropdown(
                numWeekOfMonth: numWeekOfMonth,
                numOfDay: numOfDay,
                daysOfWeek: daysOfWeek,
                onWeekChanged: (int value) {
                  setState(() {
                    numWeekOfMonth = value;
                    workMeetingSchedule?.numWeekOfMonth = numWeekOfMonth;
                  });
                },
                onDayChanged: (String value) {
                  setState(() {
                    numOfDay = daysOfWeek.indexOf(value);
                    workMeetingSchedule?.numOfDay = numOfDay;
                  });
                },
              ),
            ),
            CheckboxListTile(
              value: numDayOfMonthCheckbox,
              onChanged: (value) {
                setState(() {
                  numDayOfMonthCheckbox = value!;
                  numDayNumWeekCheckbox = !numDayNumWeekCheckbox;
                  workMeetingSchedule?.checkboxstatus = numDayNumWeekCheckbox;
                });
              },
              title: DayOfMonthSelectorDropDown(
                dayOfMonth: dayOfMonth ?? 1,
                onDayOfMonthChanged: (int value) {
                  setState(() {
                    dayOfMonth = value;
                    workMeetingSchedule?.dayOfMonth = dayOfMonth;
                  });
                },
              ),
            ),
            GroupInfo(
              key: groupInfoKey,
              shedule: workMeetingSchedule,
              namegroup: serviceUser?.group ?? '',
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: TextButton.icon(
                  onPressed: () {
                    if (isAutorization &&
                        serviceUser!.type.contains(ServiceName.chairperson)) {
                      workMeetingSchedule = WorkMeetingSchedule(
                          numWeekOfMonth: numWeekOfMonth,
                          numOfDay: numOfDay,
                          selectedDays: selectedDays,
                          dayOfMonth: dayOfMonth,
                          checkboxstatus: numDayNumWeekCheckbox);
                      loadprofitGroup();
                      addMeetingEvents(); // Добавляем Новые собрания группы
                      Event
                          .saveEventsToFirestore(); // Сохранем все события в файл
                      ProfitGroup.saveProfitGroups(
                          profitGroup); // Сохраняем пустой лист с графиком всех собраний в файл
                      Deductions.saveDeductions(listdeductions);
                      WorkMeetingSchedule.saveWorkMeetingSchedule(
                          // Сохраняем состояние комбобоксов Собраний и РАБОЧИХ собраний в файл
                          workMeetingSchedule!);
                      ProtocolMeeting.saveProtocolMeetings(listprotocolMeeting);
                      GroupsAA groupAA = groupInfoKey.currentState!
                          .getGroupsAAFromTextFields();
                      GroupsAA.saveGroupAA(groupAA);

                      setState(() {});

                      infoSnackBar(context, 'Данные сохранены');
                    } else {
                      infoSnackBar(context, 'Недостаточно прав');
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Сохранить',
                  ),
                  style: AppButtonStyle.dialogButton,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Выбор графика для события Рабочее собрание по дням месяца
class DayOfMonthSelectorDropDown extends StatelessWidget {
  final int dayOfMonth;
  final ValueChanged<int> onDayOfMonthChanged;
  const DayOfMonthSelectorDropDown(
      {super.key, required this.dayOfMonth, required this.onDayOfMonthChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      //alignment: WrapAlignment.spaceAround,
      children: [
        const Text(
          'Каждое',
          style: AppTextStyle.valuesstyle,
        ),
        DropdownButton<int>(
          value: dayOfMonth,
          items: List<DropdownMenuItem<int>>.generate(
            31,
            (index) => DropdownMenuItem(
              value: index + 1,
              child: Text((index + 1).toString()),
            ),
          ),
          onChanged: (int? value) {
            if (value != null) {
              onDayOfMonthChanged(value);
            }
          },
        ),
        const Text(
          'число месяца',
          style: AppTextStyle.valuesstyle,
        ),
      ],
    );
  }
}

// Выбор графика для события Рабочее собрание по номеру недели и номеру дня
class WeekSelectorDropdown extends StatelessWidget {
  final int? numWeekOfMonth;
  final int? numOfDay;
  final List<String>? daysOfWeek;
  final ValueChanged<int> onWeekChanged;
  final ValueChanged<String> onDayChanged;

  const WeekSelectorDropdown({
    super.key,
    required this.numWeekOfMonth,
    required this.numOfDay,
    required this.daysOfWeek,
    required this.onWeekChanged,
    required this.onDayChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      //alignment: WrapAlignment.spaceAround,
      children: [
        const Text(
          'Каждый ',
          style: AppTextStyle.valuesstyle,
        ),
        // Номер недели в месяце
        DropdownButton<int>(
          value: numWeekOfMonth,
          items: List<DropdownMenuItem<int>>.generate(
            6,
            (index) => DropdownMenuItem(
              value: index + 1,
              child: index == 5 ? Text('Посл.') : Text((index + 1).toString()),
            ),
          ),
          onChanged: (int? value) {
            if (value != null) {
              onWeekChanged(value);
            }
          },
        ),
        DropdownButton<String>(
          value: daysOfWeek?[numOfDay ?? 1],
          items: daysOfWeek?.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? value) {
            if (value != null) {
              onDayChanged(value);
            }
          },
        ),
        const Text(
          ' месяца',
          style: AppTextStyle.valuesstyle,
        ),
      ],
    );
  }
}

GlobalKey<_GroupInfoState> groupInfoKey = GlobalKey();

class GroupInfo extends StatefulWidget {
  final WorkMeetingSchedule? shedule;
  final String namegroup;
  const GroupInfo({
    super.key,
    required this.shedule,
    required this.namegroup,
  });

  @override
  State<GroupInfo> createState() => _GroupInfoState();
}

class _GroupInfoState extends State<GroupInfo> {
  bool _isExpanded = false;
  TextEditingController citycontroller = TextEditingController();
  TextEditingController areacontroller = TextEditingController();
  TextEditingController metrocontroller = TextEditingController();
  List<TextEditingController> timingcontroller = [];
  TextEditingController bigspeakercontroller = TextEditingController();
  TextEditingController minispeakercontroller = TextEditingController();
  TextEditingController adresscontroller = TextEditingController();
  TextEditingController phonecontroller = TextEditingController();
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController urlcontroller = TextEditingController();
  TextEditingController additionalInfocontroller = TextEditingController();
  GroupsAA? groupInfo;
  WorkMeetingSchedule? _schedule;

  @override
  void initState() {
    loadInfoGroup().then((value) {
      setState(() {
           _schedule = widget.shedule;
    fillFormFields();    
      });
    });


    super.initState();
  }

  Future<GroupsAA?> loadInfoGroup() async {
groupInfo = await GroupsAA.loadGroupAA();
    return groupInfo;
  }

  @override
  void didUpdateWidget(covariant GroupInfo oldWidget) {
    if (oldWidget.shedule != widget.shedule) {
      setState(() {
        _schedule = widget.shedule;
        fillFormFields();
      });
    }
    super.didUpdateWidget(oldWidget);
  }

// Загрузка полей
  void fillFormFields() {
    timingcontroller.clear();
    citycontroller.text = groupInfo?.city ?? '';
    areacontroller.text = groupInfo?.area ?? '';
    metrocontroller.text = groupInfo?.metro ?? '';
    bigspeakercontroller.text = groupInfo?.bigspeaker ?? '';
    minispeakercontroller.text = groupInfo?.minispeaker ?? '';
    adresscontroller.text = groupInfo?.adress ?? '';
    phonecontroller.text = groupInfo?.phone ?? '';
    emailcontroller.text = groupInfo?.email ?? '';
    urlcontroller.text = groupInfo?.url ?? '';
    additionalInfocontroller.text = groupInfo?.additionalInfo ?? '';

    if (groupInfo?.timing != null) {
      for (var timing in groupInfo!.timing!) {
        timingcontroller.add(TextEditingController(text: timing['time']));
      }
    } else {
      if (_schedule?.selectedDays != null) {
        for (var day in _schedule!.selectedDays) {
          timingcontroller.add(TextEditingController());
        }
      }
    }
  }

// Сохранение значений полей
  GroupsAA getGroupsAAFromTextFields() {
    String wotkmeeting = '';

    if (widget.shedule != null) {
      widget.shedule!.checkboxstatus!
          ? wotkmeeting =
              'Каждый ${_schedule?.numOfDay} ${daysOfWeek[_schedule!.numWeekOfMonth!]} месяца'
          : wotkmeeting = 'Каждое ${_schedule!.dayOfMonth} число месяца';
    }

    List<Map<String, String>> timing = [];

// Проверяем, что размерности списков совпадают
    if (timingcontroller.length == _schedule?.selectedDays.length) {
      for (int i = 0; i < timingcontroller.length; i++) {
        String time = timingcontroller[i].text;
        String day = _schedule!.selectedDays[i];

        timing.add({'time': time, 'day': day});
      }
    } else {
      print('Размерности списков не совпадают');
    }
    timingcontroller.clear();
    return GroupsAA(
      name: widget.namegroup,
      city: citycontroller.text,
      area: areacontroller.text,
      metro: metrocontroller.text,
      timing: timing,
      workmeeting: wotkmeeting,
      bigspeaker: bigspeakercontroller.text,
      minispeaker: minispeakercontroller.text,
      adress: adresscontroller.text,
      phone: phonecontroller.text,
      email: emailcontroller.text,
      url: urlcontroller.text,
      additionalInfo: additionalInfocontroller.text,
    );
  }

  @override
  void dispose() {
    citycontroller.dispose();
    areacontroller.dispose();
    metrocontroller.dispose();
    timingcontroller.forEach((controller) {
      controller.dispose();
    });
    timingcontroller.clear();
    bigspeakercontroller.dispose();
    minispeakercontroller.dispose();
    adresscontroller.dispose();
    phonecontroller.dispose();
    emailcontroller.dispose();
    urlcontroller.dispose();
    additionalInfocontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
        _schedule = widget.shedule;
    return FutureBuilder<GroupsAA?>(
      future: loadInfoGroup(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Center(child: Text('Ошибка загрузки данных'));
      } else {
        if (snapshot.hasData) {
          groupInfo = snapshot.data;
          fillFormFields();
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ExpansionPanelList(
                  dividerColor: Colors.blueGrey,
                  expansionCallback: (int index, bool isExpanded) {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  children: <ExpansionPanel>[
                    ExpansionPanel(
                      backgroundColor: AppColor.cardColor,
                      headerBuilder: (BuildContext context, bool isExpanded) {
                        return ListTile(
                          title: Center(
                              child: Text(
                            'Информация о группе',
                            style: AppTextStyle.menutextstyle,
                          )),
                        );
                      },
                      body: Column(
                        children: [
                          Text(
                            'Местоположение:',
                            style: AppTextStyle.valuesstyle,
                            textAlign: TextAlign.center,
                          ),
                          AnimatedTextAndTextFieldWidget(
                            text: 'Город:',
                            controller: citycontroller,
                          ),
                          AnimatedTextAndTextFieldWidget(
                            text: 'Район:',
                            controller: areacontroller,
                          ),
                          AnimatedTextAndTextFieldWidget(
                            text: 'Метро:',
                            controller: metrocontroller,
                          ),
                          AnimatedTextAndTextFieldWidget(
                            text: 'Адрес:',
                            controller: adresscontroller,
                          ),
                          Text(
                            'Время собраний:',
                            style: AppTextStyle.valuesstyle,
                            textAlign: TextAlign.center,
                          ),
                          if (_schedule?.selectedDays != null)
                            for (int i = 0; i < _schedule!.selectedDays.length; i++)
                              TextAndTextFieldWidget(
                                controller: timingcontroller[i],
                                text: '${_schedule?.selectedDays[i]}',
                              ),
                          Text(
                            'Дополнительно:',
                            style: AppTextStyle.valuesstyle,
                            textAlign: TextAlign.center,
                          ),
                          AnimatedTextAndTextFieldWidget(
                            text: 'Большое спикерское:',
                            controller: bigspeakercontroller,
                          ),
                          AnimatedTextAndTextFieldWidget(
                            text: 'Мини-спикерское:',
                            controller: minispeakercontroller,
                          ),
                          AnimatedTextAndTextFieldWidget(
                            text: 'Телефон:',
                            controller: phonecontroller,
                          ),
                          AnimatedTextAndTextFieldWidget(
                            text: 'Почта:',
                            controller: emailcontroller,
                          ),
                          AnimatedTextAndTextFieldWidget(
                            text: 'Сайт:',
                            controller: urlcontroller,
                          ),
                          AnimatedTextAndTextFieldWidget(
                            text: 'Доп.информация:',
                            controller: additionalInfocontroller,
                          ),
                        ],
                      ),
                      isExpanded: _isExpanded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        } else {
          return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ExpansionPanelList(
                  dividerColor: Colors.blueGrey,
                  expansionCallback: (int index, bool isExpanded) {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  children: <ExpansionPanel>[
                    ExpansionPanel(
                      backgroundColor: AppColor.cardColor,
                      headerBuilder: (BuildContext context, bool isExpanded) {
                        return ListTile(
                          title: Center(
                              child: Text(
                            'Информация о группе',
                            style: AppTextStyle.menutextstyle,
                          )),
                        );
                      },
                      body: Column(
                        children: [
                          Text(
                            'Местоположение:',
                            style: AppTextStyle.valuesstyle,
                            textAlign: TextAlign.center,
                          ),
                          AnimatedTextAndTextFieldWidget(
                            text: 'Город:',
                            controller: citycontroller,
                          ),
                          AnimatedTextAndTextFieldWidget(
                            text: 'Район:',
                            controller: areacontroller,
                          ),
                          AnimatedTextAndTextFieldWidget(
                            text: 'Метро:',
                            controller: metrocontroller,
                          ),
                          AnimatedTextAndTextFieldWidget(
                            text: 'Адрес:',
                            controller: adresscontroller,
                          ),
                          Text(
                            'Время собраний:',
                            style: AppTextStyle.valuesstyle,
                            textAlign: TextAlign.center,
                          ),
                          if (_schedule?.selectedDays != null)
                            for (int i = 0; i < _schedule!.selectedDays.length; i++)
                              TextAndTextFieldWidget(
                                controller: timingcontroller[i],
                                text: '${_schedule?.selectedDays[i]}',
                              ),
                          Text(
                            'Дополнительно:',
                            style: AppTextStyle.valuesstyle,
                            textAlign: TextAlign.center,
                          ),
                          AnimatedTextAndTextFieldWidget(
                            text: 'Большое спикерское:',
                            controller: bigspeakercontroller,
                          ),
                          AnimatedTextAndTextFieldWidget(
                            text: 'Мини-спикерское:',
                            controller: minispeakercontroller,
                          ),
                          AnimatedTextAndTextFieldWidget(
                            text: 'Телефон:',
                            controller: phonecontroller,
                          ),
                          AnimatedTextAndTextFieldWidget(
                            text: 'Почта:',
                            controller: emailcontroller,
                          ),
                          AnimatedTextAndTextFieldWidget(
                            text: 'Сайт:',
                            controller: urlcontroller,
                          ),
                          AnimatedTextAndTextFieldWidget(
                            text: 'Доп.информация:',
                            controller: additionalInfocontroller,
                          ),
                        ],
                      ),
                      isExpanded: _isExpanded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        }
      }
      },
    );
  }
}
