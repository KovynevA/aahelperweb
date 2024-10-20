import 'dart:math';

import 'package:aahelper/helper/stylemenu.dart';
import 'package:aahelper/helper/utils.dart';
import 'package:aahelper/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

class Speakercard extends StatefulWidget {
  const Speakercard({super.key});

  @override
  State<Speakercard> createState() => _SpeakercardState();
}

class _SpeakercardState extends State<Speakercard> {
  DateTime _selectedDay = kToday;
  DateTime _focusedDay = kToday;
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  List<SpeakerMeeting>? listSpeakerMeeting;
  bool showSpeakerCard = false;

  @override
  void initState() {
    setState(() {
      _loadSpeakerMeetings();
      _loadEvents();
      showSpeakerCard = false;
    });

    super.initState();
  }

// Загрузить спикерские собрания
  void _loadSpeakerMeetings() {
    SpeakerMeeting.loadMeetingsFromFirestore().then((value) {
      setState(() {
        listSpeakerMeeting = value;
      });
    });
  }

  // Загрузить календарь событий
  void _loadEvents() async {
    try {
      await Event.loadEventsFromFirestore(
          RepeatOptions('Не повторять', RepeatType.none));
    } catch (e) {
      debugPrint('Ошибка Загрузки файла событий: $e');
    }
  }

// Вызвать календарь для выбора даты
  void _showCalendarDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TableCalendar<Event>(
                    rowHeight: 40,
                    locale: 'ru_RU',
                    firstDay: kFirstDay,
                    lastDay: kLastDay,
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: _calendarFormat,
                    eventLoader: _getEventsForDay,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Month',
                    },
                    headerStyle: const HeaderStyle(
                      titleTextStyle: AppTextStyle.menutextstyle,
                    ),
                    daysOfWeekHeight: 20,
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: AppTextStyle.valuesstyle,
                      weekendStyle: AppTextStyle.valuesstyle,
                    ),
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: AppTextStyle.spantextstyle,
                      weekendTextStyle: AppTextStyle.spantextstyle,
                      selectedTextStyle: AppTextStyle.valuesstyle,
                      todayTextStyle: AppTextStyle.valuesstyle,
                      outsideDaysVisible: false,
                      markerSize: 10,
                      markerDecoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(width: 2.0, color: Colors.orange),
                        color: Colors.black,
                      ),
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                      });
                    },
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showSpeakerCard = false;
                      Navigator.of(context).pop();
                      refresh();
                    },
                    style: AppButtonStyle.iconButton,
                    child: const Text(
                      'Выбрать',
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  // обновить виджеты
  void refresh() {
    setState(() {});
  }

  List<Event> _getEventsForDay(DateTime day) {
    return kEvents[day] ?? [];
  }

// Получить строчку даты из DateTime
  String getTextDate(DateTime date) {
    final String year = date.year.toString();
    final String month =
        date.month > 10 ? date.month.toString() : '0${date.month}';
    final String day = date.day > 10 ? date.day.toString() : '0${date.day}';
    return '$year:$month:$day';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Text(
                  'Дата собрания: ',
                  style: AppTextStyle.valuesstyle,
                ),
                IconButton(
                  onPressed: () {
                    _showCalendarDialog(context);
                  },
                  icon: const Icon(
                    Icons.calendar_month,
                    color: Colors.brown,
                  ),
                  iconSize: 24,
                ),
                Text(
                  getTextDate(_selectedDay),
                  style: AppTextStyle.valuesstyle,
                ),
              ],
            ),
          ),
          if (SpeakerMeeting.findSpeakerMeetingByDate(
                  listSpeakerMeeting ?? [], _selectedDay) !=
              null)
            AddSpeakerForSelectedDate(
              listSpeakerMeeting: listSpeakerMeeting ?? [],
              selectedDay: _selectedDay,
            ),
          if (SpeakerMeeting.findSpeakerMeetingByDate(
                      listSpeakerMeeting ?? [], _selectedDay) ==
                  null &&
              !showSpeakerCard)
            TextButton(
              onPressed: () {
                setState(() {
                  showSpeakerCard = true;
                });
              },
              style: AppButtonStyle.dialogButton,
              child: const Text('Добавить'),
            ),
          if (showSpeakerCard)
            AddSpeakerForSelectedDate(
              listSpeakerMeeting: listSpeakerMeeting ?? [],
              selectedDay: _selectedDay,
            ),
        ],
      ),
    );
  }
}

// Карточка с добавлением спикера
class AddSpeakerForSelectedDate extends StatefulWidget {
  const AddSpeakerForSelectedDate(
      {super.key, required this.selectedDay, required this.listSpeakerMeeting});
  final List<SpeakerMeeting> listSpeakerMeeting;
  final DateTime selectedDay;

  @override
  State<AddSpeakerForSelectedDate> createState() =>
      _AddSpeakerForSelectedDateState();
}

class _AddSpeakerForSelectedDateState extends State<AddSpeakerForSelectedDate> {
  TextEditingController? nameSpeakerController = TextEditingController();
  TextEditingController? phoneeSpeakerController = TextEditingController();
  TextEditingController? homegroupController = TextEditingController();
  TextEditingController? sobrietyPeriodrController = TextEditingController();
  TextEditingController? themeController = TextEditingController();
  SpeakerMeeting? speakerMeeting;
  ServiceUser? serviceuser;

  @override
  void initState() {
    super.initState();
    getServiceUser();
    _updateDataForSelectedDay(widget.selectedDay);
  }

  @override
  void didUpdateWidget(covariant AddSpeakerForSelectedDate oldWidget) {
    if (widget.selectedDay != oldWidget.selectedDay) {
      _updateDataForSelectedDay(widget.selectedDay);
    }
    super.didUpdateWidget(oldWidget);
  }

  void getServiceUser() async {
    if (isAutorization) {
      serviceuser =
          await ServiceUser.getServiceUserFromFirestore(currentUser!.email!);
    }
  }

  void _updateDataForSelectedDay(DateTime selectedDay) {
    if (widget.listSpeakerMeeting.isNotEmpty) {
      speakerMeeting = SpeakerMeeting.findSpeakerMeetingByDate(
          widget.listSpeakerMeeting, selectedDay);
      if (speakerMeeting != null) {
        nameSpeakerController =
            TextEditingController(text: speakerMeeting!.speakerName);
        phoneeSpeakerController =
            TextEditingController(text: speakerMeeting!.phone ?? '');
        homegroupController =
            TextEditingController(text: speakerMeeting!.homegroup ?? '');
        sobrietyPeriodrController = TextEditingController(
            text: (speakerMeeting!.sobrietyPeriod ?? 0).toString());
        themeController =
            TextEditingController(text: speakerMeeting!.theme ?? '');
      } else {
        nameSpeakerController = TextEditingController();
        phoneeSpeakerController = TextEditingController();
        homegroupController = TextEditingController();
        sobrietyPeriodrController = TextEditingController();
        themeController = TextEditingController();
      }
    } else {
      nameSpeakerController = TextEditingController();
      phoneeSpeakerController = TextEditingController();
      homegroupController = TextEditingController();
      sobrietyPeriodrController = TextEditingController();
      themeController = TextEditingController();
    }
  }

// Сохранить введенные данные спикера
  void onSaveListSpeakermeeting(int index) {
    SpeakerMeeting newSpeakerMeeting = SpeakerMeeting(
      date: widget.selectedDay,
      speakerName: nameSpeakerController!.text,
      phone: phoneeSpeakerController!.text,
      homegroup: homegroupController!.text,
      sobrietyPeriod: sobrietyPeriodrController!.text == ''
          ? '0'
          : sobrietyPeriodrController!.text,
      theme: themeController!.text,
    );

    // Проверяем, существует ли уже запись для выбранной даты
    if (index != -1) {
      widget.listSpeakerMeeting[index] = newSpeakerMeeting;
    } else {
      widget.listSpeakerMeeting.add(newSpeakerMeeting);
    }
    widget.listSpeakerMeeting.sort((a, b) => a.date.compareTo(b.date));
    SpeakerMeeting.saveMeetingsToFirestore(widget.listSpeakerMeeting);
// Удаляем событие Спикерская и затем добавляем новое или отредактированное
    Event.removeSpeakerEvent(widget.selectedDay);
    final eventsForSelectedDay = kEvents[widget.selectedDay] ?? <Event>[];
    final textevent = 'Спикерская. Спикер: ${newSpeakerMeeting.speakerName}, \n'
        'Дом. группа: ${newSpeakerMeeting.homegroup}, \n'
        'Срок трезвости: ${newSpeakerMeeting.sobrietyPeriod}, \n'
        'Тема: ${newSpeakerMeeting.theme}';
    kEvents[widget.selectedDay] = [
      ...eventsForSelectedDay,
      Event(textevent, RepeatOptions('Не повторять', RepeatType.none)),
    ];
    Provider.of<ServiceProvider>(context, listen: false)
        .updateSpeakerData(Random().toString());
    Event.saveEventsToFirestore();
  }

// Удалить спикера
  void onDeleteListSpeakermeeting(int index) {
    SpeakerMeeting.deleteSpeakerMeetingFromFirestore(
        widget.listSpeakerMeeting[index]);
    widget.listSpeakerMeeting.removeAt(index);
    _updateDataForSelectedDay(widget.selectedDay);
    Provider.of<ServiceProvider>(context, listen: false)
        .updateSpeakerData(Random().toString());
    // Удаляем из Событий
    Event.removeSpeakerEvent(widget.selectedDay);
  }

  @override
  void dispose() {
    nameSpeakerController?.dispose();
    phoneeSpeakerController?.dispose();
    homegroupController?.dispose();
    sobrietyPeriodrController?.dispose();
    themeController?.dispose();
    super.dispose();
  }

  void _launchPhoneApp(String phoneNumber) async {
    final Uri phoneLaunchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneLaunchUri)) {
      await launchUrl(phoneLaunchUri);
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

  @override
  Widget build(BuildContext context) {
    int index = widget.listSpeakerMeeting
        .indexWhere((meeting) => compareDate(meeting.date, widget.selectedDay));
    return Column(
      children: [
        SizedBox(
          // height: MediaQuery.of(context).size.height * 0.3,
          width: MediaQuery.of(context).size.width * 0.97,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            shadowColor: Colors.black,
            elevation: 5.0,
            child: Column(
              children: [
                SizedBox(
                  height: 15,
                ),
                AnimatedTextFieldStyleWidget(
                  text: 'Имя:',
                  controller: nameSpeakerController!,
                  sizeheight: 50,
                  sizewidth: MediaQuery.of(context).size.width * 0.8,
                  decoration: Decor.decorTextField,
                ),
                SizedBox(
                  height: 15,
                ),
                GestureDetector(
                  onDoubleTap: () {
                    _launchPhoneApp(phoneeSpeakerController!.text);
                  },
                  child: AnimatedTextFieldStyleWidget(
                    text: 'Телефон спикера:',
                    controller: phoneeSpeakerController!,
                    sizeheight: 50,
                    sizewidth: MediaQuery.of(context).size.width * 0.8,
                    decoration: Decor.decorTextField,
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                AnimatedTextFieldStyleWidget(
                  text: 'Домашняя группа:',
                  controller: homegroupController!,
                  sizeheight: 50,
                  sizewidth: MediaQuery.of(context).size.width * 0.8,
                  decoration: Decor.decorTextField,
                ),
                SizedBox(
                  height: 15,
                ),
                AnimatedTextFieldStyleWidget(
                  text: 'Срок трезвости:',
                  sizeheight: 50,
                  controller: sobrietyPeriodrController!,
                  sizewidth: MediaQuery.of(context).size.width * 0.8,
                  decoration: Decor.decorTextField,
                ),
                SizedBox(
                  height: 15,
                ),
                AnimatedTextFieldStyleWidget(
                  text: 'Тема:',
                  controller: themeController!,
                  sizeheight: 50,
                  sizewidth: MediaQuery.of(context).size.width * 0.8,
                  decoration: Decor.decorTextField,
                ),
                SizedBox(
                  height: 15,
                ),
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  onSaveListSpeakermeeting(index);
                  (serviceuser!.type.contains(ServiceName.chairperson) ||
                          serviceuser!.type.contains(ServiceName.leading))
                      ? infoSnackBar(context, 'Спикер сохранён')
                      : infoSnackBar(context, 'Недостаточно прав');
                });
              },
              style: AppButtonStyle.dialogButton,
              child: const Text('Сохранить'),
            ),
            index != -1
                ? TextButton(
                    onPressed: () {
                      setState(() {
                        onDeleteListSpeakermeeting(index);
                        (serviceuser!.type.contains(ServiceName.chairperson) ||
                                serviceuser!.type.contains(ServiceName.leading))
                            ? infoSnackBar(context, 'Спикер Удалён')
                            : infoSnackBar(context, 'Недостаточно прав');
                      });
                    },
                    style: AppButtonStyle.dialogButton,
                    child: const Text('Удалить'),
                  )
                : Container(),
          ],
        ),
      ],
    );
  }
}
