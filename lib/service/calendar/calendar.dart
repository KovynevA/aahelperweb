import 'dart:collection';

import 'package:aahelper/helper/stylemenu.dart';
import 'package:aahelper/main.dart';
import 'package:aahelper/service/calendar/authorization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../helper/utils.dart';

class ChairEventCalendar extends StatefulWidget {
  final void Function() updateStateCalendar;
  const ChairEventCalendar({
    super.key,
    required this.updateStateCalendar,
  });

  @override
  State<ChairEventCalendar> createState() => _ChairEventCalendarState();
}

class _ChairEventCalendarState extends State<ChairEventCalendar> {
  late final ValueNotifier<List<Event>> _selectedEvents;
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  RepeatOptions? _selectedRepeatOption;

  @override
  void initState() {
    setState(() {
      _selectedDay = _focusedDay;
      _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
      _selectedRepeatOption = RepeatOptions('Не повторять', RepeatType.none);
      _loadEvents();
    });
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ChairEventCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void updateCalendar() {
    setState(() {
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
      _loadEvents();
    });
  }

  // Загрузить календарь событий
  void _loadEvents() async {
    try {
      await Event.loadEventsFromFirestore(_selectedRepeatOption!)
          .then((value) => setState(() {
                _selectedEvents.value = _getEventsForDay(_selectedDay!);
              }));
    } catch (e) {
      debugPrint('Ошибка Загрузки файла событий: $e');
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    return kEvents[day] ?? [];
  }

// Добавить событие в календарь
  void _addEvent() {
    TextEditingController newEventController = TextEditingController();
    if (_selectedDay != null) {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Название события'),
                        TextFieldStyleWidget(
                          decoration: Decor.decorTextField,
                          sizewidth: double.infinity,
                          onChanged: (value) {
                            newEventController.text = value;
                          },
                        ),
                        const Text('Повторение'),
                        DropdownButton<RepeatOptions>(
                          value: _selectedRepeatOption,
                          onChanged: (RepeatOptions? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedRepeatOption = newValue;
                              });
                            }
                          },
                          items: <RepeatOptions>[
                            RepeatOptions('Не повторять', RepeatType.none),
                            RepeatOptions('Еженедельно', RepeatType.weekly),
                            RepeatOptions('Ежемесячно', RepeatType.monthly),
                            RepeatOptions('Ежегодно', RepeatType.year),
                            RepeatOptions('Период', RepeatType.other),
                          ].map<DropdownMenuItem<RepeatOptions>>(
                              (RepeatOptions repeat) {
                            return DropdownMenuItem<RepeatOptions>(
                              value: repeat,
                              child: Text(repeat.label),
                            );
                          }).toList(),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Center(
                          child: TextButton(
                            style: AppButtonStyle.iconButton,
                            onPressed: () {
                              onPressEvent(setState, newEventController);
                              updateCalendar();

                              Navigator.of(context).pop();
                            },
                            child: const Text('OK'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    }
  }

// Обработка выбора режима повтора события
  void onPressEvent(
      StateSetter setState, TextEditingController newEventController) async {
    final eventsForSelectedDay = kEvents[_selectedDay] ?? <Event>[];
    kEvents[_selectedDay!] = [
      ...eventsForSelectedDay,
      Event(newEventController.text, _selectedRepeatOption!),
    ];
    if (_selectedRepeatOption?.type == RepeatType.weekly) {
      DateTime nextDate = _selectedDay!.add(const Duration(days: 7));
      while (nextDate.isBefore(kLastDay)) {
        final eventsForNextDate = kEvents[nextDate] ?? <Event>[];
        eventsForNextDate
            .add(Event(newEventController.text, _selectedRepeatOption!));
        kEvents[nextDate] = List.from(eventsForNextDate);
        nextDate = nextDate.add(const Duration(days: 7));
      }
    } else if (_selectedRepeatOption!.type == RepeatType.monthly) {
      DateTime nextDate = DateTime(
          _selectedDay!.year, _selectedDay!.month + 1, _selectedDay!.day);
      while (nextDate.isBefore(kLastDay)) {
        final eventsForNextDate = kEvents[nextDate] ?? <Event>[];
        eventsForNextDate
            .add(Event(newEventController.text, _selectedRepeatOption!));
        kEvents[nextDate] = List.from(eventsForNextDate);
        nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
      }
    } else if (_selectedRepeatOption!.type == RepeatType.year) {
      // Логика для создания повторяющихся событий каждый год
      DateTime nextDate = DateTime(
          _selectedDay!.year + 1, _selectedDay!.month, _selectedDay!.day);
      while (nextDate.isBefore(kLastDay)) {
        final eventsForNextDate = kEvents[nextDate] ?? <Event>[];
        eventsForNextDate
            .add(Event(newEventController.text, _selectedRepeatOption!));
        kEvents[nextDate] = List.from(eventsForNextDate);
        nextDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day);
      }
    } else if (_selectedRepeatOption!.type == RepeatType.other) {
      // Получаем номер недели в месяце и день недели текущей даты
      int weekNumber = (_selectedDay!.day + 6) ~/ 7;
      int dayOfWeek = _selectedDay!.weekday;
      // Логика для создания повторяющихся событий в каждом следующем месяце
      DateTime nextDate = _selectedDay!
          .add(const Duration(days: 1)); // Начинаем с следующего дня
      while (nextDate.isBefore(kLastDay)) {
        int nextWeekNumber = (nextDate.day + 6) ~/ 7;
        int nextDayOfWeek = nextDate.weekday;
        if (nextWeekNumber == weekNumber && nextDayOfWeek == dayOfWeek) {
          final eventsForNextDate = kEvents[nextDate] ?? <Event>[];
          eventsForNextDate
              .add(Event(newEventController.text, _selectedRepeatOption!));
          kEvents[nextDate] = List.from(eventsForNextDate);
        }
        nextDate =
            nextDate.add(const Duration(days: 1)); // Переходим к следующему дню
      }
    }
    _selectedEvents.value = _getEventsForDay(_selectedDay!);
    isAutorization
        ? {
            Event.saveEventsToFirestore(),
            infoSnackBar(context, 'Событие сохранено')
          }
        : infoSnackBar(context, 'Не сохранено. Вы не авторизованы');
  }

// Удалить все связанные события
  void _deleteAllLinkedEvents(Event event) {
    if (_selectedDay != null) {
      setState(() {
        final updatedEvents =
            LinkedHashMap<DateTime, List<Event>>.from(kEvents);

        updatedEvents.forEach((day, events) {
          updatedEvents[day] =
              events.where((e) => e.title != event.title).toList();
        });

        kEvents.clear();
        kEvents.addAll(updatedEvents);

        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      });

      Event.saveEventsToFirestore();
    }
  }

// Удалить одно событие
  void _deleteEvent(Event event) async {
    if (_selectedDay != null) {
      final eventsForSelectedDay = kEvents[_selectedDay];
      if (eventsForSelectedDay != null) {
        setState(() {
          kEvents[_selectedDay!] =
              eventsForSelectedDay.where((e) => e != event).toList();
          _selectedEvents.value = _getEventsForDay(_selectedDay!);
        });
      }
    }
    Event.saveEventsToFirestore();
  }

// Очистить календарь от событий
  void _clearCalendar() async {
    setState(() {
      kEvents.clear();
      _selectedEvents.value = [];
    });
    Event.saveEventsToFirestore();
  }

  // Метод для редактирования событий
  void _editEvent(Event event) {
    TextEditingController editEventController =
        TextEditingController(text: event.title);
    showModalBottomSheet(
      backgroundColor: AppColor.backgroundColor,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Название события'),
                    TextFieldStyleWidget(
                      decoration: Decor.decorTextField,
                      sizewidth: double.infinity,
                      controller: editEventController,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Center(
                      child: TextButton(
                        style: AppButtonStyle.iconButton,
                        onPressed: () {
                          onEditEvent(setState, event, editEventController);
                          updateCalendar();
                          infoSnackBar(context, 'Событие обновлено');
                          Navigator.of(context).pop();
                        },
                        child: const Text('OK'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

// Обработка редактирования события
  void onEditEvent(StateSetter setState, Event event,
      TextEditingController editEventController) async {
    setState(() {
      kEvents[_selectedDay!] = kEvents[_selectedDay!]!
          .map((e) => e == event
              ? Event(editEventController.text, _selectedRepeatOption!)
              : e)
          .toList();
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    });
    Event.saveEventsToFirestore();
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ServiceProvider>(context, listen: true);
    _selectedEvents.value = _getEventsForDay(_selectedDay!);
    return SingleChildScrollView(
      child: Column(
        children: [
          AuthentificationWidget(
            updateCallbackSettingPage: updateCalendar,
          ),
          Container(
            margin: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: AppColor.cardColor,
              border: Border.all(width: 1.5, color: Colors.brown),
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.blueGrey,
                  blurRadius: 8.0,
                  offset: Offset(1.0, 2.0),
                )
              ],
            ),
            child: TableCalendar<Event>(
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
                _selectedEvents.value = _getEventsForDay(selectedDay);
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
          ),
          ValueListenableBuilder<List<Event>>(
            valueListenable: _selectedEvents,
            builder: (context, value, _) {
              return SizedBox(
                height: MediaQuery.of(context).size.height - 100,
                child: ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    return Dismissible(
                      key: Key(value[index].title),
                      onDismissed: (direction) {
                        if (direction == DismissDirection.endToStart) {
                          _deleteAllLinkedEvents(
                              value[index]); // Удалить все связанные события
                        } else {
                          _deleteEvent(value[index]); // Удалить одно событие
                        }
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        child: const Icon(Icons.delete),
                      ),
                      child: GestureDetector(
                        onLongPress: () {
                          if (_selectedEvents.value.isNotEmpty) {
                            _editEvent(_selectedEvents.value[index]);
                          }
                        },
                        child: Card(
                          color: AppColor.cardColor,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 4.0,
                          ),
                          child: ListTile(
                            title: Text(value[index].title),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CustomFloatingActionButton(
                    icon: Icons.cleaning_services,
                    onPressed: () async {
                      final ServiceUser? serviceUser = await getServiceUser();
                      if (serviceUser != null &&
                          serviceUser.type.contains(ServiceName.chairperson)) {
                        _clearCalendar;
                      } else {
                        infoSnackBar(context, 'Недостаточно прав');
                      }
                    }),
                CustomFloatingActionButton(
                  icon: Icons.add_box,
                  onPressed: _addEvent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
