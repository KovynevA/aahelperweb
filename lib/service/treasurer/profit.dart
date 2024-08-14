import 'package:aahelper/helper/stylemenu.dart';
import 'package:aahelper/helper/utils.dart';
import 'package:flutter/material.dart';

class Profit extends StatefulWidget {
  const Profit({super.key});

  @override
  State<Profit> createState() => _ProfitState();
}

class _ProfitState extends State<Profit> {
  List<DateTime> groupMeetingDates = [];
  List<ProfitGroup> listProfitGroup = [];
  int flippedCardIndex = -1;
  int? initialIndex;
  final ScrollController _scrollController = ScrollController();
  List<Deductions> listDeductions = [];
  double? heightCard;
  double? widthCard;

  @override
  void initState() {
    loadProfitJsonFile();
    loadDeductions();
    super.initState();
  }

  @override
  void didChangeDependencies() {
   
    super.didChangeDependencies();
  }

  void _flipCard(int index) {
    setState(() {
      if (flippedCardIndex == index) {
        flippedCardIndex =
            -1; // Если карточка уже перевернута, перевернуть обратно
      } else {
        flippedCardIndex = index; // Перевернуть выбранную карточку
      }
    });
  }

// Поиск индекса ближайшей к текущей дате
  int findNDateIndex(List<DateTime> dates) {
    int index = dates.indexWhere(
        (date) => date.isAfter(kToday) || date.isAtSameMomentAs(kToday));
    if (index == -1) {
      // Если не найдено даты, не позже текущей, то выбираем последнюю дату в списке
      index = dates.length - 1;
    }
    return index;
  }

// Загрузка списка событий и вычленение дат из него + сортировка
// А также устанавливаем индекс для прокрутки
  void loadProfitJsonFile() async {
    listProfitGroup = [];
    groupMeetingDates = [];
    listProfitGroup = await ProfitGroup.loadProfitGroups() ?? [];
 final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Определяем маленький экран
    isSmallScreen
        ? heightCard = MediaQuery.of(context).size.height * 0.33
        : heightCard = MediaQuery.of(context).size.height * 0.24;
    widthCard = MediaQuery.of(context).size.width * 0.9;
    setState(() {
      updateMeetingDates();
      //скроллим список до ближайшей даты
      _scrollToInitialIndex();
    });
  }

// Загрузить рабочки для ограничения датами итоговой суммы.
  void loadDeductions() async {
    listDeductions = await Deductions.loadDeductions();
  }

// Функция скроллинга
  void _scrollToInitialIndex() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        (initialIndex! - 1) * heightCard!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.ease,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateProfitGroup(ProfitGroup updatedGroup) {
    setState(() {
      // Найти индекс обновляемой группы в списке
      int index = listProfitGroup
          .indexWhere((group) => group.date == updatedGroup.date);
      if (index != -1) {
        // Обновить группу в списке
        listProfitGroup[index] = updatedGroup;
      }
    });
  }

  // Функция для обновления groupMeetingDates
  void updateMeetingDates() {
    groupMeetingDates = listProfitGroup.map((e) => e.date).toList();
    // Также может понадобиться обновить initialIndex, если он используется
    initialIndex = findNDateIndex(groupMeetingDates);
  }

  // УДАЛЕНИЕ ОДНОГО дня из списка собраний
  void removeProfitGroup(int index) async {
    listProfitGroup.removeAt(index);
    ProfitGroup.saveProfitGroups(listProfitGroup);
    updateMeetingDates(); // Обновляем groupMeetingDates после удаления
    _scrollToInitialIndex();
    setState(() {});
  }

  // УДАЛЕНИЕ дня недели из списка собраний
  void removeEventsForDay(int dayIndex) async {
    listProfitGroup.removeWhere((event) => event.date.weekday == dayIndex);
    ProfitGroup.saveProfitGroups(listProfitGroup);
    updateMeetingDates(); // Обновляем groupMeetingDates после удаления
    _scrollToInitialIndex();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: groupMeetingDates.length,
      itemExtent: heightCard, // Установка фиксированной высоты элементов списка
      itemBuilder: (context, index) {
        final key = ValueKey(groupMeetingDates[index]);
        return GestureDetector(
          onTap: () {
            _flipCard(index);
          },
          child: Center(
            child: SizedBox(
              key: key,
              width: widthCard, // Установка фиксированной ширины карточки
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                shadowColor: Colors.black,
                elevation: 5.0,
                child: Stack(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 1000),
                      child: flippedCardIndex == index
                          ? BackOfCardWidget(
                              flipCard: () {
                                _flipCard(index);
                              },
                              index: index,
                              onUpdate:
                                  _updateProfitGroup, // Передача функции обновления
                            )
                          : FrontOfCardWidget(
                              index: index,
                              listProfitGroup: listProfitGroup,
                              listDeductions: listDeductions,
                              onRemove:
                                  removeProfitGroup, // Для удаления одного элемента
                              onRemoveForDay:
                                  removeEventsForDay, // Для удаления всех элементов дня
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Передняя сторона карточки
class FrontOfCardWidget extends StatefulWidget {
  final int index;
  final List<ProfitGroup> listProfitGroup;
  final List<Deductions> listDeductions;
  final Function(int) onRemove; // Для удаления одного элемента
  final Function(int)
      onRemoveForDay; // Для удаления всех элементов определенного дня
  const FrontOfCardWidget({
    super.key,
    required this.index,
    required this.listProfitGroup,
    required this.onRemove,
    required this.onRemoveForDay,
    required this.listDeductions,
  });

  @override
  State<FrontOfCardWidget> createState() => _FrontOfCardWidgetState();
}

class _FrontOfCardWidgetState extends State<FrontOfCardWidget> {
  int? weekday;
  int? day;
  int? month;
  int? year;
  double? profit;
  double? expensive;
  List<String> listdeleteOption = [
    'Удалить 1 день',
    'Удалить дни недели',
    'Очистить список'
  ];
  String? deleteOption;
  ServiceUser? serviceuser;
  ProfitGroup? totalProfit;
  double? totalplus;
  double? totalminus;
  double? balance;

  @override
  void initState() {
    deleteOption = listdeleteOption[0];
    calculateMoney();
    getServiceUser();
    getFirstDate();
    super.initState();
  }

  void getServiceUser() async {
    if (isAutorization) {
      serviceuser =
          await ServiceUser.getServiceUserFromFirestore(currentUser!.email!);
    }
  }

  void calculateMoney() {
    weekday = widget.listProfitGroup[widget.index].date.weekday - 1;
    day = widget.listProfitGroup[widget.index].date.day;
    month = widget.listProfitGroup[widget.index].date.month;
    year = widget.listProfitGroup[widget.index].date.year;
    profit = (widget.listProfitGroup[widget.index].sevenTraditioncash ?? 0) +
        (widget.listProfitGroup[widget.index].sevenTraditioncard ?? 0) +
        (widget.listProfitGroup[widget.index].profitliteratura ?? 0) +
        (widget.listProfitGroup[widget.index].profitother ?? 0);
    expensive = (widget.listProfitGroup[widget.index].tea ?? 0) +
        (widget.listProfitGroup[widget.index].expensiveliteratura ?? 0) +
        (widget.listProfitGroup[widget.index].medal ?? 0) +
        (widget.listProfitGroup[widget.index].postmail ?? 0) +
        (widget.listProfitGroup[widget.index].expensiveother ?? 0);
  }

// Меню удаления дня, всех дней недели или очистка списка
  void showSelectedWeekDay(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                backgroundColor: AppColor.backgroundColor,
                insetPadding: EdgeInsets.zero,
                scrollable: true,
                title: Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Удалить день: ',
                          style: AppTextStyle.valuesstyle,
                        ),
                        DropdownButton<String>(
                          value: deleteOption,
                          items: listdeleteOption.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              deleteOption = newValue;
                            });
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          style: AppButtonStyle.iconButton,
                          onPressed: () {
                            if (deleteOption == listdeleteOption[0]) {
                              widget.onRemove(widget.index);
                            } else if (deleteOption == listdeleteOption[1]) {
                              widget.onRemoveForDay((weekday! + 1));
                            } else {
                              widget.listProfitGroup.clear();
                              clearProfitGroups();
                              updateWidget();
                            }
                            ProfitGroup.saveProfitGroups(
                                widget.listProfitGroup);
                            infoSnackBar(context, 'Удалено');
                            Navigator.of(context).pop();
                          },
                          child: const Text('Ok'),
                        ),
                        TextButton(
                          style: AppButtonStyle.iconButton,
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Выход',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        });
  }

// Очистить список
  void clearProfitGroups() async {
    await ProfitGroup.clearProfitGroups();
  }

  void updateWidget() {
    setState(
      () {},
    );
  }

  void calculateTotalofPeriod() {
    totalplus = (totalProfit?.sevenTraditioncash ?? 0) +
        (totalProfit?.sevenTraditioncard ?? 0) +
        (totalProfit?.profitliteratura ?? 0) +
        (totalProfit?.profitother ?? 0);

    totalminus = (totalProfit?.tea ?? 0) +
        (totalProfit?.expensiveliteratura ?? 0) +
        (totalProfit?.medal ?? 0) +
        (totalProfit?.postmail ?? 0) +
        (totalProfit?.expensiveother ?? 0);
  }

// Поиск первой ближайшей даты из списка к заданной дате
  void getFirstDate() {
    DateTime currentDate = widget.listProfitGroup[widget.index].date;
    Deductions? nearestDeduction;
    for (var i = 0; i < widget.listDeductions.length - 1; i++) {
      Deductions deduction = widget.listDeductions[i];
      if (deduction.date.isBefore(currentDate) ||
          deduction.date.isAtSameMomentAs(currentDate)) {
        if (nearestDeduction == null ||
            deduction.date.isAfter(nearestDeduction.date)) {
          nearestDeduction = deduction;
        }
      }
    }
    balance = nearestDeduction?.balance;

    DateTime startDate = nearestDeduction?.date ?? currentDate;
    getTotalProfit(startDate, currentDate);
  }

  // Загрузить отчет по запрошенным датам
  void getTotalProfit(DateTime date1, DateTime date2) {
    List<ProfitGroup> listtotal = widget.listProfitGroup.where((profitGroup) {
      return profitGroup.date.isAfter(date1) &&
              profitGroup.date.isBefore(date2) ||
          profitGroup.date.isAtSameMomentAs(date1) ||
          profitGroup.date.isAtSameMomentAs(date2);
    }).toList();

    totalProfit = ProfitGroup.totalProfit(listtotal);

    calculateTotalofPeriod();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        if (isAutorization &&
            ((serviceuser!.type.contains(ServiceName.chairperson) ||
                serviceuser!.type.contains(ServiceName.treasurer)))) {
          showSelectedWeekDay(context);
        } else {
          infoSnackBar(context, 'Недостаточно прав');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.cardColor,
          border: Border.all(width: 1.0),
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${daysOfWeek[weekday ?? 0]}, $day/$month/$year',
                      style: AppTextStyle.menutextstyle,
                    ),
                    Text(
                      'Собрано: $profit',
                      style: AppTextStyle.valuesstyle,
                    ),
                    Text(
                      'Расход: $expensive',
                      style: AppTextStyle.valuesstyle,
                    ),
                    Text(
                      'Всего за день: ${(profit ?? 0) - (expensive ?? 0)}',
                      style: AppTextStyle.valuesstyle,
                    ),
                    Text(
                      'Итого в кассе: ${((totalplus ?? 0) + (balance ?? 0) - (totalminus ?? 0)).toStringAsFixed(2)}',
                      style: AppTextStyle.valuesstyle,
                    ),
                    Text(
                        '*Итог учитывает остаток с последнего рабочего собрания',
                        style: AppTextStyle.spantextstyle,
                        softWrap: true),
                  ],
                ),
              ),
              Container(
                width: MediaQuery.of(context).size.width * 0.24,
                height: MediaQuery.of(context).size.height * 0.24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    fit: BoxFit.fill,
                    image: AssetImage('assets/images/money.jpg'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//Обратная сторона карточки
class BackOfCardWidget extends StatefulWidget {
  final VoidCallback flipCard;
  final int index;
  final Function(ProfitGroup) onUpdate; // Функция обновления

  const BackOfCardWidget(
      {super.key,
      required this.flipCard,
      required this.index,
      required this.onUpdate});

  @override
  State<BackOfCardWidget> createState() => _BackOfCardWidgetState();
}

class _BackOfCardWidgetState extends State<BackOfCardWidget> {
  List<ProfitGroup> listProfitGroup = [];
  late ProfitGroup _profitGroup;
  List<Map<String, dynamic>> profitFields = [];
  List<Map<String, dynamic>> expensiveFields = [];
  ServiceUser? serviceuser;

  @override
  void initState() {
    super.initState();
    loadProfitData();
    getServiceUser();
  }

  Future<void> loadProfitData() async {
    List<ProfitGroup> loadedData = await ProfitGroup.loadProfitGroups() ?? [];
    setState(() {
      listProfitGroup = loadedData;
      if (listProfitGroup.isNotEmpty) {
        _profitGroup = listProfitGroup[widget.index];
      }
    });
  }

  void getServiceUser() async {
    if (isAutorization) {
      serviceuser =
          await ServiceUser.getServiceUserFromFirestore(currentUser!.email!);
    }
  }

  void _removeLastProfitField() {
    setState(() {
      if (profitFields.isNotEmpty) {
        profitFields.removeLast();
      }
    });
  }

  void _addProfitFields() {
    profitFields.add({
      'dropdownValue': '7 традиция нал',
      'textValue': '',
      'dropdownController': TextEditingController(),
      'textController': TextEditingController(),
    });
  }

  void _removeExpensiveField() {
    setState(() {
      if (expensiveFields.isNotEmpty) {
        expensiveFields.removeLast();
      }
    });
  }

  void _addExpensiveFields() {
    expensiveFields.add({
      'dropdownValue': 'чай',
      'textValue': '',
      'dropdownController': TextEditingController(),
      'textController': TextEditingController(),
    });
  }

  void _showAddProfitModal(BuildContext context) {
    profitFields = [];
    expensiveFields = [];

    for (var field in _profitGroup.toMap().entries) {
      if (field.value != null) {
        if (field.key == '7 традиция нал' ||
            field.key == '7 традиция карта' ||
            field.key == 'литература' ||
            field.key == 'другое') {
          profitFields.add({
            'dropdownValue': field.key,
            'textValue': field.value.toString(),
            'dropdownController': TextEditingController(),
            'textController':
                TextEditingController(text: field.value.toString()),
          });
        } else {
          expensiveFields.add({
            'dropdownValue': field.key,
            'textValue': field.value.toString(),
            'dropdownController': TextEditingController(),
            'textController':
                TextEditingController(text: field.value.toString()),
          });
        }
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            backgroundColor: AppColor.backgroundColor,
            insetPadding: EdgeInsets.zero,
            scrollable: true,
            title: Row(
              children: [
                const Text(
                  'Введите Доход группы',
                  style: AppTextStyle.menutextstyle,
                ),
                IconButton(
                    onPressed: () {
                      setState(() {
                        _addProfitFields();
                      });
                    },
                    icon: const Icon(Icons.add_box)),
                IconButton(
                    onPressed: () {
                      setState(() {
                        _removeLastProfitField();
                      });
                    },
                    icon: const Icon(Icons.remove_circle)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  children: [
                    for (int index = 0; index < profitFields.length; index++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TreasureDropdownButton(
                              decoration: Decor.decorDropDownButton,
                              styleText: AppTextStyle.valuesstyle,
                              items: const [
                                '7 традиция нал',
                                '7 традиция карта',
                                'литература',
                                'другое'
                              ],
                              value: profitFields[index]['dropdownValue'],
                              onChanged: (String? newValue) {
                                setState(() {
                                  profitFields[index]['dropdownValue'] =
                                      newValue!;
                                  profitFields[index]['textValue'] =
                                      ''; // Сбросить значение текста
                                });
                                profitFields[index]['textController']
                                    .clear(); // Очистить поле TextField
                              },
                            ),
                            TextFieldStyleWidget(
                              decoration: Decor.decorTextField,
                              sizeheight: 45,
                              controller: profitFields[index]['textController'],
                              onChanged: (value) {
                                profitFields[index]['textValue'] =
                                    value; // Сохраняем введенный текст в переменную text
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      'Введите Расход группы',
                      style: AppTextStyle.menutextstyle,
                    ),
                    IconButton(
                        onPressed: () {
                          setState(() {
                            _addExpensiveFields();
                          });
                        },
                        icon: const Icon(Icons.add_box)),
                    IconButton(
                        onPressed: () {
                          setState(() {
                            _removeExpensiveField();
                          });
                        },
                        icon: const Icon(Icons.remove_circle)),
                  ],
                ),
                Column(
                  children: [
                    for (int index = 0; index < expensiveFields.length; index++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TreasureDropdownButton(
                              decoration: Decor.decorDropDownButton,
                              styleText: AppTextStyle.valuesstyle,
                              items: const [
                                'книги',
                                'чай',
                                'медали',
                                'открытки',
                                'прочее'
                              ],
                              value: expensiveFields[index]['dropdownValue'],
                              onChanged: (String? newValue) {
                                setState(() {
                                  expensiveFields[index]['dropdownValue'] =
                                      newValue!;
                                  expensiveFields[index]['textValue'] =
                                      ''; // Сбросить значение текста
                                });
                                expensiveFields[index]['textController']
                                    .clear(); // Очистить поле TextField
                              },
                            ),
                            TextFieldStyleWidget(
                              decoration: Decor.decorTextField,
                              sizeheight: 45,
                              controller: expensiveFields[index]
                                  ['textController'],
                              onChanged: (value) {
                                expensiveFields[index]['textValue'] =
                                    value; // Сохраняем введенный текст в переменную text
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      style: AppButtonStyle.iconButton,
                      onPressed: () {
                        _saveValueToProfitGroup();
                        listProfitGroup[widget.index] = _profitGroup;
                        ProfitGroup.saveProfitGroups(listProfitGroup);
                        updateData();
                        (serviceuser!.type.contains(ServiceName.chairperson) ||
                                serviceuser!.type
                                    .contains(ServiceName.treasurer))
                            ? infoSnackBar(context, 'Сохранено')
                            : infoSnackBar(context, 'Недостаточно прав');
                        Navigator.of(context).pop();
                      },
                      child: const Text('Сохранить'),
                    ),
                    TextButton(
                      style: AppButtonStyle.iconButton,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Выход',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
      },
    ).then((value) {
      widget.onUpdate(_profitGroup);
      setState(() {});
    });
  }

  double _doubleparse(Map<String, dynamic> field) {
    double result = 0.0;
    if (field.containsKey('textValue')) {
      String textValue = field['textValue'].toString();
      if (textValue.isNotEmpty) {
        result = double.parse(textValue);
      }
    }
    return result;
  }

// Сохранение значений из текстового поля в _profitGroup
// Проверяем условие, что поле непустое перед записью
  void _saveValueToProfitGroup() {
    _profitGroup.clear();
    for (var field in profitFields) {
      if (field['dropdownValue'] == '7 традиция нал') {
        _profitGroup.sevenTraditioncash = _doubleparse(field);
      } else if (field['dropdownValue'] == '7 традиция карта') {
        _profitGroup.sevenTraditioncard = _doubleparse(field);
      } else if (field['dropdownValue'] == 'литература') {
        _profitGroup.profitliteratura = _doubleparse(field);
      } else if (field['dropdownValue'] == 'другое') {
        _profitGroup.profitother = _doubleparse(field);
      }
    }

    for (var field in expensiveFields) {
      if (field['dropdownValue'] == 'книги') {
        _profitGroup.expensiveliteratura = _doubleparse(field);
      } else if (field['dropdownValue'] == 'чай') {
        _profitGroup.tea = _doubleparse(field);
      } else if (field['dropdownValue'] == 'медали') {
        _profitGroup.medal = _doubleparse(field);
      } else if (field['dropdownValue'] == 'открытки') {
        _profitGroup.postmail = _doubleparse(field);
      } else if (field['dropdownValue'] == 'прочее') {
        _profitGroup.expensiveother = _doubleparse(field);
      }
    }
  }

  void updateData() {
    setState(() {
      // Обновите данные в родительском виджете GroupMeetingsScreen
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return listProfitGroup.isEmpty
        ? const CircularProgressIndicator()
        : GestureDetector(
            onTap: widget
                .flipCard, // Вызываем функцию для обратного переворота карточки
            onLongPress: () {
              if (isAutorization &&
                  ((serviceuser!.type.contains(ServiceName.chairperson) ||
                      serviceuser!.type.contains(ServiceName.treasurer)))) {
                _showAddProfitModal(context);
              } else {
                infoSnackBar(context, 'Недостаточно прав');
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColor.deleteCardColor,
                border: Border.all(width: 2.0),
                borderRadius: BorderRadius.circular(15.0),
              ),
              padding: const EdgeInsets.symmetric(vertical: 5),
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                        child: ProfitTextWidget(profitGroup: _profitGroup)),
                    Expanded(
                        child: ExpensiveTextWidget(profitGroup: _profitGroup)),
                  ],
                ),
              ),
            ),
          );
  }
}

// Колонка с отображением деталей расходов
class ExpensiveTextWidget extends StatelessWidget {
  final ProfitGroup profitGroup;
  const ExpensiveTextWidget({
    super.key,
    required this.profitGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
        color: AppColor.deleteCardColor,
        shape: BoxShape.rectangle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.white,
            blurRadius: 10.0,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const Text(
            'Расход: ',
            style: AppTextStyle.valuesstyle,
          ),
          Text(
            'Книги: ${profitGroup.expensiveliteratura ?? 0}',
            style: AppTextStyle.minimalsstyle,
          ),
          Text(
            'Чай: ${profitGroup.tea ?? 0}',
            style: AppTextStyle.minimalsstyle,
          ),
          Text(
            'Медали: ${profitGroup.medal ?? 0}',
            style: AppTextStyle.minimalsstyle,
          ),
          Text(
            'Открытки: ${profitGroup.postmail ?? 0}',
            style: AppTextStyle.minimalsstyle,
          ),
          Text(
            'Прочее: ${profitGroup.expensiveother ?? 0}',
            style: AppTextStyle.minimalsstyle,
          ),
        ],
      ),
    );
  }
}

// Колонка с отображением деталей доходов
class ProfitTextWidget extends StatelessWidget {
  final ProfitGroup profitGroup;
  const ProfitTextWidget({
    super.key,
    required this.profitGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
        color: AppColor.deleteCardColor,
        shape: BoxShape.rectangle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.white,
            blurRadius: 10.0,
            offset: Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const Text(
            'Доход: ',
            style: AppTextStyle.valuesstyle,
          ),
          Text(
            '7 традиция нал: ${profitGroup.sevenTraditioncash ?? 0}',
            style: AppTextStyle.minimalsstyle,
          ),
          Text(
            '7 традиция карта: ${profitGroup.sevenTraditioncard ?? 0}',
            style: AppTextStyle.minimalsstyle,
          ),
          Text(
            'Литература: ${profitGroup.profitliteratura ?? 0}',
            style: AppTextStyle.minimalsstyle,
          ),
          Text(
            'Другое: ${profitGroup.profitother ?? 0}',
            style: AppTextStyle.minimalsstyle,
          ),
        ],
      ),
    );
  }
}
