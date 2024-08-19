// Настройки группы
import 'package:aahelper/helper/stylemenu.dart';
import 'package:aahelper/helper/utils.dart';
import 'package:aahelper/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsGroup extends StatefulWidget {
  final String title;
  final Function() callback;
  const SettingsGroup({
    super.key,
    required this.title,
    required this.callback,
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
    Event.loadEventsFromFirestore(
            RepeatOptions('Не повторять', RepeatType.none))
        .then((_) {
      widget.callback();
    });
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
    // Provider.of<ServiceProvider>(context, listen: false)
    //     .updateListProfit(profitGroup);
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

// Временная функция переноса
  // void moveData() async {
  //   ServiceUser? serviceUser = await getServiceUser();
  //   final String nameGroupCollection = serviceUser!.group;
  //   final firestore = FirebaseFirestore.instance;
  //   DocumentReference namegroupDocRef =
  //       firestore.collection(nameGroupCollection).doc('namegroup_id');

  //   List<String> collectionNames = [
  //     'books',
  //     'complete',
  //     'completedQuestions',
  //     'deductions',
  //     'events',
  //     'profitGroups',
  //     'protocolMeetings',
  //     'protocolWorkMeeting',
  //     'questions',
  //     'serviceCard',
  //     'shop',
  //     'speakerMeetings',
  //     'workMeetingSchedule',
  //   ]; // Добавьте сюда остальные названия вложенных коллекций

  //   for (String collectionName in collectionNames) {
  //     CollectionReference collectionRef =
  //         namegroupDocRef.collection(collectionName);
  //     QuerySnapshot snapshot = await collectionRef.get();

  //     if (snapshot.docs.isNotEmpty) {
  //       for (QueryDocumentSnapshot doc in snapshot.docs) {
  //         firestore
  //             .collection('allgroups')
  //             .doc(nameGroupCollection)
  //             .collection(collectionName)
  //             .doc(doc.id)
  //             .set(doc.data() as Map<String, dynamic>);
  //       }
  //     } else {
  //       print('No documents found in collection $collectionName');
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AuthentificationWidget(updateCallbackSettingPage: updateState),
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
                        ProtocolMeeting.saveProtocolMeetings(
                            listprotocolMeeting);
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
              // TextButton(
              //   onPressed: moveData,
              //   child: Text('data'),
              // ),
            ],
          ),
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
    return Wrap(
      // mainAxisAlignment: MainAxisAlignment.spaceAround,
      alignment: WrapAlignment.spaceAround,
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
    return Wrap(
      //mainAxisAlignment: MainAxisAlignment.spaceAround,
      alignment: WrapAlignment.spaceAround,
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

class AuthentificationWidget extends StatefulWidget {
  final VoidCallback updateCallbackSettingPage;
  const AuthentificationWidget(
      {super.key, required this.updateCallbackSettingPage});

  @override
  State<AuthentificationWidget> createState() => _AuthentificationWidgetState();
}

class _AuthentificationWidgetState extends State<AuthentificationWidget> {
  final TextEditingController logincontroller = TextEditingController();
  final TextEditingController passwordcontroller = TextEditingController();
  TextEditingController nameleading = TextEditingController();
  String? selectedNameGroup;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  ServiceUser? serviceuser;
  String admingroup = 'Вешняки';
  TextEditingController adminGroupController = TextEditingController();
  List<String> groups = [];
  StateSetter? dialogStateSetter;

  @override
  void initState() {
    isAutorization
        ? {
            loadServiceUser(),
          }
        : {
            fetchGroups().then((onValue) {
              setState(() {
                selectedNameGroup = 'Выберите группу';
                nameleading.text = '';
              });
            })
          };
    super.initState();
  }

  void loadServiceUser() async {
    ServiceUser? user = await getServiceUser();
    if (user != null) {
      setState(() {
        serviceuser = user;
        selectedNameGroup = serviceuser?.group;
        nameleading.text = serviceuser!.name;
      });
    }
  }

  // callback
  void onCallbackSettingPage() {
    widget
        .updateCallbackSettingPage(); // Вызов колбэка для обновления календаря в MyHomePage
  }

  void onCreateUserFromFireStore() {
    if (serviceuser == null) {
      ServiceUser? serviceUser = ServiceUser(
        selectedNameGroup!,
        nameleading.text,
        uid: currentUser!.uid,
        email: currentUser!.email!,
        type: [ServiceName.user],
      );
      ServiceUser.saveServiceUserToFirestore(serviceUser);
      onCallbackSettingPage();
      if (currentUser != null) {
        infoSnackBar(context, 'Регистрация успешна');
      } else {
        infoSnackBar(context, 'Регистрация НЕ успешна');
      }
      loadServiceUser();
      setState(() {});
    } else {
      selectedNameGroup = serviceuser?.group;
      nameleading.text = serviceuser?.name ?? '';
      infoSnackBar(context, 'Пользователь существует');
    }
  }

// Создать нового пользователя в базе (регистрация)
  void createUser() async {
    if (logincontroller.text.isNotEmpty &&
        passwordcontroller.text.isNotEmpty &&
        nameleading.text.isNotEmpty &&
        selectedNameGroup != 'Выберете группу') {
      try {
        await _auth.createUserWithEmailAndPassword(
          email: logincontroller.text,
          password: passwordcontroller.text,
        );
        isAutorization = true;
        currentUser = FirebaseAuth.instance.currentUser;
        onCreateUserFromFireStore();
        setState(() {});
      } catch (e) {
        String errorMessage = '';
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'weak-password':
              errorMessage =
                  'Слабый пароль. Пароль должен содержать не менее 6 символов.';
              break;
            case 'email-already-in-use':
              errorMessage = 'Пользователь с таким email уже зарегистрирован.';
              break;
            // Другие возможные причины ошибок
            default:
              errorMessage = 'Произошла ошибка при регистрации пользователя.';
          }
        }
        // Обработка ошибок при регистрации
        if (mounted) {
          infoSnackBar(context, errorMessage);
        }
      }
    } else {
      infoSnackBar(context, 'Необходимо заполнить все поля');
    }
  }

  Future<void> fetchGroups() async {
    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('allgroups').get();

      if (snapshot.docs.isNotEmpty) {
        List<String> loadedGroups = snapshot.docs.map((doc) => doc.id).toList();

        groups = loadedGroups;
      } else {
        print('No groups found in Firestore');
      }
    } catch (e) {
      print('Error fetching groups: $e');
    }
  }

  // Диалоговое окно выбора или добавления группы для админа
  void showDialogSelectedGroupForAdmin() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          dialogStateSetter = setState;
          return AlertDialog(
            backgroundColor: AppColor.backgroundColor,
            title: Text(
              'Меню выбора групп Администратором',
              style: AppTextStyle.valuesstyle,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  alignment: WrapAlignment.spaceAround,
                  children: [
                    Text(
                      'Выберете \n группу',
                      style: AppTextStyle.menutextstyle,
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 2),
                      decoration: Decor.decorDropDownButton,
                      child: DropdownButton<String>(
                        value: admingroup,
                        items: groups.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: AppTextStyle.valuesstyle,
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newvalue) {
                          setState(() {
                            admingroup = newvalue!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 15,
                ),
                Center(
                  child: TextButton(
                    style: AppButtonStyle.dialogButton,
                    onPressed: () {
                      // Perform action with selectedGroup
                      ServiceUser? user = ServiceUser(admingroup, 'Андрей',
                          uid: currentUser!.uid,
                          email: currentUser!.email!,
                          type: [ServiceName.admin, ServiceName.chairperson]);
                      serviceuser = user;
                      selectedNameGroup = serviceuser?.group;
                      nameleading.text = serviceuser!.name;
                      ServiceUser.saveServiceUserToFirestore(serviceuser!);
                      Navigator.of(context).pop();
                      onCallbackSettingPage();
                    },
                    child: Text('Выбрать группу'),
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                TextAndTextFieldWidget(
                    sizewidth: MediaQuery.of(context).size.width * 0.28,
                    text: 'Новая группа',
                    controller: adminGroupController),
              ],
            ),
            actions: <Widget>[
              Center(
                child: TextButton(
                  style: AppButtonStyle.dialogButton,
                  onPressed: () {
                    setState(() {
                      addNewGroup();
                      // onCallbackSettingPage();
                    });
                  },
                  child: Text('Добавить группу'),
                ),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> addNewGroup() async {
    await FirebaseFirestore.instance
        .collection('allgroups')
        .doc(adminGroupController.text)
        .set({});

    groups.add(adminGroupController.text);
    adminGroupController.clear();
    dialogStateSetter!(() {}); // Вызываем StateSetter для обновления виджета
  }

// Авторизация зарегистрированного пользователя
  void signIn() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: logincontroller.text,
        password: passwordcontroller.text,
      );
      isAutorization = true;
      currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        if (currentUser?.email == 'kovinas@bk.ru') {
          // await fetchGroups();

          showDialogSelectedGroupForAdmin();
        } else {
          loadServiceUser();
          infoSnackBar(context, 'Вход выполнен');

          onCallbackSettingPage();
        }
      }
      loadQuestionsForWorkMeeting();
    } catch (e) {
      // Обработка ошибок при входе
      debugPrint(e.toString());
      if (mounted) {
        infoSnackBar(context, 'Вход не выполнен, ${e.toString}');
      }
    }
  }

  void loadQuestionsForWorkMeeting() async {
    Provider.of<ServiceProvider>(context, listen: false).loadData();
  }

  void signOutUser() async {
    try {
      await _auth.signOut();
      await fetchGroups();
      setState(() {
        currentUser = null;
        serviceuser = null;
        isAutorization = false;
        infoSnackBar(context, 'Вы вышли из аккаунта');
        onCallbackSettingPage();
      });
    } catch (e) {
      debugPrint('Ошибка выхода пользователя${e.toString()}');
      infoSnackBar(context, 'Ошибка выхода пользователя${e.toString()}');
    }
  }

  void resetPassword(TextEditingController? emailController) {
    //TextEditingController? emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Сброс забытого пароля',
            style: AppTextStyle.menutextstyle,
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  'Введите email',
                  style: AppTextStyle.valuesstyle,
                ),
                TextField(
                  controller: emailController ?? TextEditingController(),
                ),
                Text(
                  'Нажав на кнопку "Изменить", на Вашу почту придет письмо, в котором будет ссылка на изменение пароля. Старый пароль больше действовать не будет!',
                  softWrap: true,
                  style: AppTextStyle.minimalsstyle,
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (emailController?.text != '') {
                      await _auth.sendPasswordResetEmail(
                          email: emailController!.text);
                      Navigator.of(context).pop;
                    } else {
                      infoSnackBar(context, 'Введите свой email');
                    }
                  },
                  child: Text('Сбросить пароль'),
                  style: AppButtonStyle.dialogButton,
                ),
                ElevatedButton(
                  onPressed: Navigator.of(context).pop,
                  child: Text('Отмена'),
                  style: AppButtonStyle.dialogButton,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    logincontroller.dispose();
    passwordcontroller.dispose();
    nameleading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return (currentUser != null)
        ? Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Center(
                  child: Text(
                    'Группа ${serviceuser?.group}',
                    style: AppTextStyle.menutextstyle,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    'Добро пожаловать, ${serviceuser?.name}',
                    style: AppTextStyle.valuesstyle,
                  ),
                  ElevatedButton(
                    style: AppButtonStyle.dialogButton,
                    onPressed: () {
                      signOutUser();
                    },
                    child: const Text('Выйти'),
                  ),
                ],
              ),
            ],
          )
        : Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Column(
                    children: [
                      Text(
                        'Почта:',
                        style: AppTextStyle.menutextstyle,
                      ),
                      SizedBox(
                        height: 20.0,
                      ),
                      Text(
                        'Пароль:',
                        style: AppTextStyle.menutextstyle,
                      ),
                      SizedBox(
                        height: 20.0,
                      ),
                      Text(
                        'Ваше имя:',
                        style: AppTextStyle.menutextstyle,
                      ),
                      SizedBox(
                        height: 20.0,
                      ),
                      Text(
                        'Группа АА:',
                        style: AppTextStyle.menutextstyle,
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(
                        height: 5.0,
                      ),
                      TextFieldStyleWidget(
                        decoration: Decor.decorTextField,
                        sizewidth: MediaQuery.of(context).size.width / 2,
                        sizeheight: 40,
                        controller: logincontroller,
                        //  onChanged: (p0) => {},
                      ),
                      const SizedBox(
                        height: 5.0,
                      ),
                      TextFieldStyleWidget(
                        decoration: Decor.decorTextField,
                        sizewidth: MediaQuery.of(context).size.width / 2,
                        sizeheight: 40,
                        controller: passwordcontroller,
                      ),
                      const SizedBox(
                        height: 5.0,
                      ),
                      TextFieldStyleWidget(
                        decoration: Decor.decorTextField,
                        sizewidth: MediaQuery.of(context).size.width / 2,
                        sizeheight: 40,
                        controller: nameleading,
                        // onChanged: (p0) => {},
                      ),
                      const SizedBox(
                        height: 5.0,
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 2),
                        width: MediaQuery.of(context).size.width / 1.8,
                        height: 50,
                        decoration: Decor.decorDropDownButton,
                        child: DropdownButtonFormField(
                          hint: Text('Выберите группу'),
                          style: AppTextStyle.valuesstyle,
                          value: selectedNameGroup,
                          items: groups.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: AppTextStyle.valuesstyle,
                                textAlign: TextAlign.center,
                              ),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            setState(() {
                              selectedNameGroup = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 18.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(
                      onPressed: () {
                        createUser();
                        setState(() {});
                      },
                      style: AppButtonStyle.dialogButton,
                      child: const Text('Зарегистрироваться'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          signIn();
                        });
                      },
                      style: AppButtonStyle.dialogButton,
                      child: const Text('Войти'),
                    ),
                  ],
                ),
              ),
              Center(
                  child: TextButton(
                onPressed: () => resetPassword(logincontroller),
                child: Text('Сбросить пароль'),
              )),
            ],
          );
  }
}
