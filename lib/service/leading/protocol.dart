import 'package:aahelper/helper/stylemenu.dart';
import 'package:aahelper/helper/utils.dart';
import 'package:aahelper/service/treasurer/workmeeting.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class ProtocolPage extends StatefulWidget {
  const ProtocolPage({super.key});

  @override
  State<ProtocolPage> createState() => _ProtocolPageState();
}

class _ProtocolPageState extends State<ProtocolPage> {
  DateTime _selectedDay = kToday;
  DateTime _focusedDay = kToday;
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  List<ProtocolMeeting>? listProtocolMeeting;

  @override
  void initState() {
    //_selectedDay = _focusedDay;

    _loadEvents();

    super.initState();
  }

  @override
  void didChangeDependencies() {
    _loadProtocol();
    super.didChangeDependencies();
  }

// Загрузить протоколы собраний
  void _loadProtocol() async {
    listProtocolMeeting = await ProtocolMeeting.loadProtocolMeetings();
    if (listProtocolMeeting != null) {
      setState(() {});
    }
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

  List<Event> _getEventsForDay(DateTime day) {
    return kEvents[day] ?? [];
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

// Получить строчку даты из DateTime
  String getTextDate(DateTime date) {
    final String year = date.year.toString();
    final String month =
        date.month > 10 ? date.month.toString() : '0${date.month}';
    final String day = date.day > 10 ? date.day.toString() : '0${date.day}';
    return '$year:$month:$day';
  }

// обновить виджеты
  void refresh() {
    setState(() {});
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
          ProtocolMeeting.findProtocolMeetingByDate(
                      listProtocolMeeting ?? [], _selectedDay) ==
                  null
              ? const Text('Собрания на эту дату нет')
              : ProtocolWidget(
                  listProtocolMeeting: listProtocolMeeting,
                  selectedDay: _selectedDay,
                ),
        ],
      ),
    );
  }
}

//ПРОТОКОЛ
class ProtocolWidget extends StatefulWidget {
  const ProtocolWidget({
    super.key,
    required this.listProtocolMeeting,
    required this.selectedDay,
  });

  final List<ProtocolMeeting>? listProtocolMeeting;
  final DateTime? selectedDay;

  @override
  State<ProtocolWidget> createState() => _ProtocolWidgetState();
}

class _ProtocolWidgetState extends State<ProtocolWidget> {
  List<Map<String, dynamic>> themeFields = [];
  ProtocolMeeting? protocolMeeting;
  TextEditingController jubileeController = TextEditingController();
  TextEditingController newBieController = TextEditingController();
  TextEditingController newBieInGroupController = TextEditingController();
  TextEditingController upTo30daysController = TextEditingController();
  TextEditingController expenseController = TextEditingController();
  TextEditingController seventraditionController = TextEditingController();
  TextEditingController literaturaController = TextEditingController();
  TextEditingController waspresentController = TextEditingController();
  ServiceUser? serviceuser;
  bool _isTextFieldFocused = false;

  @override
  void initState() {
    fillProtocolMeeting();
    getServiceUser();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ProtocolWidget oldWidget) {
    themeFields = [];
    if (widget.selectedDay != oldWidget.selectedDay) {
      fillProtocolMeeting();
    }
    super.didUpdateWidget(oldWidget);
  }

  void getServiceUser() async {
    if (isAutorization) {
      serviceuser =
          await ServiceUser.getServiceUserFromFirestore(currentUser!.email!);
    }
  }

  void fillProtocolMeeting() {
    protocolMeeting = ProtocolMeeting.findProtocolMeetingByDate(
        widget.listProtocolMeeting ?? [], widget.selectedDay ?? kToday);

    for (var theme in protocolMeeting?.themeMeeting ?? []) {
      themeFields.add({
        'dropdownValue': theme.keys.first,
        'textValue': theme.values.first,
        'dropdownController': TextEditingController(),
        'textController': TextEditingController(text: theme.values.first),
      });
    }
    if (themeFields.isEmpty) {
      _addThemeFields();
    }
    jubileeController.text = protocolMeeting?.jubilee ?? '';
    newBieController.text = protocolMeeting?.newBie ?? '';
    newBieInGroupController.text = protocolMeeting?.newBieInGroup ?? '';
    upTo30daysController.text = protocolMeeting?.upTo30days ?? '';
    expenseController.text = (protocolMeeting?.expense ?? 0).toString();
    seventraditionController.text =
        (protocolMeeting?.seventradition ?? 0).toString();
    literaturaController.text = (protocolMeeting?.literatura ?? 0).toString();
    waspresentController.text = (protocolMeeting?.waspresent ?? 0).toString();
  }

// Заполнить лист темами
  void createProtocolMeetingsFromThemeFields() {
    protocolMeeting?.themeMeeting.clear(); // Очистить существующие значения
    // Проходимся по вашему themeFields
    for (var themeField in themeFields) {
      // Извлекаем необходимые значения
      String dropdownValue = themeField['dropdownValue'];
      String textValue = themeField['textValue'];

      // Создаем Map<String, String> для добавления в themeMeeting
      Map<String, String> themeMap = {
        dropdownValue: textValue,
      };

      // Добавляем созданный Map в список themeMeeting
      protocolMeeting?.themeMeeting.add(themeMap);
    }
  }

  void _addThemeFields() {
    themeFields.add({
      'dropdownValue': 'БК',
      'textValue': '',
      'dropdownController': TextEditingController(),
      'textController': TextEditingController(),
    });
  }

  void _removeThemeFields() {
    if (themeFields.isNotEmpty) {
      themeFields.removeLast();
    }
  }

// Заполняем лист протокола
  void onSaveToProtocol() {
    createProtocolMeetingsFromThemeFields();
    protocolMeeting?.jubilee = jubileeController.text;
    protocolMeeting?.newBie = newBieController.text;
    protocolMeeting?.newBieInGroup = newBieInGroupController.text;
    protocolMeeting?.upTo30days = upTo30daysController.text;
    protocolMeeting?.expense = double.parse(expenseController.text);
    protocolMeeting?.seventradition =
        double.parse(seventraditionController.text);
    protocolMeeting?.literatura = double.parse(literaturaController.text);
    protocolMeeting?.waspresent = int.parse(waspresentController.text);
  }

  // Сохранить лист с протоколами
  void onSaveListProtocolMeeting() async {
    onSaveToProtocol();
    int index = widget.listProtocolMeeting!.indexOf(protocolMeeting!);
    widget.listProtocolMeeting?[index] = protocolMeeting!;
    ProtocolMeeting.saveProtocolMeetings(widget.listProtocolMeeting!);
  }

  @override
  void dispose() {
    jubileeController.dispose();
    newBieController.dispose();
    newBieInGroupController.dispose();
    upTo30daysController.dispose();
    expenseController.dispose();
    seventraditionController.dispose();
    literaturaController.dispose();
    waspresentController.dispose();
    super.dispose();
  }

  void _handleTextFieldFocusChange(bool hasFocus) {
    setState(() {
      _isTextFieldFocused = hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ContainerForWorkMeetings(
          child: Column(
            children: [
              const Text(
                'Протокол собрания:',
                style: AppTextStyle.menutextstyle,
                textAlign: TextAlign.center,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ведущий: ',
                      style: AppTextStyle.valuesstyle,
                    ),
                    Text(
                      protocolMeeting?.leadingName ?? (serviceuser?.name ?? ''),
                      style: AppTextStyle.valuesstyle,
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.brown,
                    width: 0.5,
                  ),
                  gradient: const LinearGradient(
                    colors: [
                      AppColor.backgroundColor,
                      Color.fromARGB(255, 131, 113, 209)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      flex: 5,
                      child: Text(
                        'Тема: ',
                        style: AppTextStyle.valuesstyle,
                      ),
                    ),
                    IconButton(
                        onPressed: () {
                          setState(() {
                            _addThemeFields();
                          });
                        },
                        icon: const Icon(Icons.add_box)),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _removeThemeFields();
                        });
                      },
                      icon: const Icon(Icons.remove_circle),
                    ),
                  ],
                ),
              ),
              for (int index = 0; index < themeFields.length; index++)
                Container(
                  padding: const EdgeInsets.all(2.0),
                  decoration: const BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(
                        style: BorderStyle.solid,
                        color: Colors.brown,
                        width: 0.5,
                      ),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        AppColor.backgroundColor,
                        Color.fromARGB(255, 131, 113, 209)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Stack(
                    //  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TreasureDropdownButton(
                          styleText: AppTextStyle.minimalsstyle,
                          items: const [
                            'БК',
                            'ЕР',
                            '12х12',
                            'Жить трезвым',
                            'КЭВБ',
                            'Спикерская',
                            'Мини-спикерская',
                            'Свободная тема',
                            'Язык сердца',
                            'Пришли к убеждению',
                            'Д.Боб и ветераны',
                            'Семинар'
                          ],
                          value: themeFields[index]['dropdownValue'],
                          onChanged: (String? newValue) {
                            setState(() {
                              themeFields[index]['dropdownValue'] = newValue!;
                              themeFields[index]['textValue'] =
                                  ''; // Сбросить значение текста
                            });
                            themeFields[index]['textController']
                                .clear(); // Очистить поле TextField
                          },
                        ),
                      ),
                      Positioned.fill(
                        child: Align(
                          alignment: _isTextFieldFocused
                              ? Alignment.center
                              : Alignment.centerRight,
                          child: AnimatedTextFieldStyleWidget(
                            onFocusChanged: _handleTextFieldFocusChange,
                            sizeheight: 35,
                            sizewidth: MediaQuery.of(context).size.width * 0.36,
                            controller: themeFields[index]['textController'],
                            onChanged: (value) {
                              themeFields[index]['textValue'] =
                                  value; // Сохраняем введенный текст в переменную text
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ProtocolDialogWidget(
                controller: jubileeController,
                text: 'Юбилеи',
              ),
              ProtocolDialogWidget(
                controller: newBieController,
                text: 'Новички',
              ),
              ProtocolDialogWidget(
                controller: newBieInGroupController,
                text: '1 раз на группе',
              ),
              ProtocolDialogWidget(
                controller: upTo30daysController,
                text: 'До 30 дней',
              ),
              ProtocolDialogWidget(
                controller: expenseController,
                text: 'Расход',
              ),
              ProtocolDialogWidget(
                controller: seventraditionController,
                text: '7 традиция',
              ),
              ProtocolDialogWidget(
                controller: literaturaController,
                text: 'Литература',
              ),
              ProtocolDialogWidget(
                controller: waspresentController,
                text: 'Присутствовало',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: ElevatedButton(
            onPressed: () {
              onSaveListProtocolMeeting();
              (serviceuser!.type.contains(ServiceName.chairperson) ||
                      serviceuser!.type.contains(ServiceName.leading))
                  ? infoSnackBar(context, 'Протокол собрания сохранен')
                  : infoSnackBar(context, 'Недостаточно прав');
            },
            style: AppButtonStyle.dialogButton,
            child: const Text('Сохранить'),
          ),
        ),
      ],
    );
  }
}

// Виджет диалога текст и TextField
class ProtocolDialogWidget extends StatelessWidget {
  final TextEditingController controller;
  final String text;
  const ProtocolDialogWidget({
    super.key,
    required this.controller,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Container(
        padding: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.brown,
            width: 0.5,
          ),
          gradient: const LinearGradient(
            colors: [
              AppColor.backgroundColor,
              Color.fromARGB(255, 121, 191, 219)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: AppTextStyle.valuesstyle,
            ),
            TextFieldStyleWidget(
              controller: controller,
              sizeheight: 35,
              sizewidth: MediaQuery.of(context).size.width * 0.39,
            ),
          ],
        ),
      ),
    );
  }
}
