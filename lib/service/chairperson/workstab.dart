import 'package:aahelper/helper/stylemenu.dart';
import 'package:aahelper/helper/utils.dart';
import 'package:aahelper/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//Общий виджет рабочка
class WorksWidget extends StatefulWidget {
  const WorksWidget({super.key});

  @override
  State<WorksWidget> createState() => _WorksWidgetState();
}

class _WorksWidgetState extends State<WorksWidget> {
  List<String> questions = [];
  List<String> complitedquetions = [];
  ServiceUser? serviceUser;
  DateTime? _startDate;
  List<DateTime>? dates;

  @override
  void initState() {
    loadServiceuser();
    loadDeductions();
    super.initState();
  }

  // Лист со всеми рабочками
  void loadDeductions() async {
    List<Deductions> listDeductions = await Deductions.loadDeductions();
    if (listDeductions.isNotEmpty) {
      setState(() {
        // даты для комбобокса со всеми рабочками до сегодня
        dates = getDatesFromDeductions(listDeductions);
        _startDate = dates?.last;
      });
    }
  }

// Получить даты рабочек с фильтром, ограничивающим список до ближайшей рабочки
  List<DateTime> getDatesFromDeductions(List<Deductions> listdeductions) {
    DateTime currentDate = kToday;
    List<DateTime> dates = [];
    for (var deduction in listdeductions) {
      dates.add(deduction.date);
    }
    DateTime targetDate = dates.firstWhere((date) => date.isAfter(currentDate),
        orElse: () => dates.last);

    int startIndex = dates.indexOf(dates.first);
    int endIndex = dates.indexOf(targetDate);

    // Проверем, если текущая дата совпадает с датой списка, то кончная дата - текущая.
    if (compareDate(dates[endIndex - 1], currentDate)) {
      endIndex = endIndex - 1;
    }

    List<DateTime> filteredDates = dates.sublist(startIndex, endIndex + 1);

    return filteredDates;
  }

  void loadServiceuser() async {
    serviceUser = await getServiceUser();
  }

  Future<void> _showInputDialog(
      BuildContext context, ServiceProvider serviceProvider) async {
    String text = ''; // Переменная для временного хранения введенного текста

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColor.backgroundColor,
          title: const Text(
            'Введите повестку',
            style: AppTextStyle.valuesstyle,
          ),
          content: TextFieldStyleWidget(
            sizeheight: MediaQuery.of(context).size.height * 0.1,
            sizewidth: MediaQuery.of(context).size.width * 0.5,
            decoration: Decor.decorTextField,
            onChanged: (value) {
              text = value; // Сохраняем введенный текст в переменную text
            },
          ),
          actions: <Widget>[
            TextButton(
              style: AppButtonStyle.iconButton,
              onPressed: () {
                serviceProvider
                    .changequestions([...serviceProvider.questions, text]);
                questions.add(text);
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return date.toLocal().toIso8601String().split('T')[0];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServiceProvider>(
      builder: (context, serviceProvider, child) {
        List<String> questions = serviceProvider.questions;
        List<String> complitedquetions = serviceProvider.completedquetions;

        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(6.0),
              child: Text(
                'Повестка собрания',
                style: AppTextStyle.menutextstyle,
              ),
            ),
            LimitedBox(
              maxHeight: MediaQuery.of(context).size.height * 0.3,
              child: WorkCards(
                questions: questions,
                complitedquetions: complitedquetions,
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(6.0),
              child: Text(
                'Завершённые вопросы',
                style: AppTextStyle.menutextstyle,
              ),
            ),
            LimitedBox(
              maxHeight: MediaQuery.of(context).size.height * 0.3,
              child: ComplitedWorkCards(
                complitedquetions: complitedquetions,
                questions: questions,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DropdownButton<DateTime>(
                    hint: Text(_formatDate(_startDate!)),
                    value: _startDate,
                    onChanged: (DateTime? newValue) {
                      setState(() {
                        _startDate = newValue!;
                      });
                    },
                    items: dates?.map((DateTime date) {
                      return DropdownMenuItem<DateTime>(
                        value: date,
                        child: Text(_formatDate(date)),
                      );
                    }).toList(),
                  ),
                  CustomFloatingActionButton(
                    onPressed: () {
                      //  getServiceUser();
                      if (isAutorization &&
                          serviceUser!.type.contains(ServiceName.chairperson)) {
                        _showInputDialog(context, serviceProvider);
                      } else {
                        infoSnackBar(context, 'Недостаточно прав');
                      }
                    },
                    icon: Icons.add_box,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

//Карточки с вопросами на рабочку
class WorkCards extends StatefulWidget {
  final List<String> questions;
  final List<String> complitedquetions;
  const WorkCards(
      {super.key, required this.questions, required this.complitedquetions});

  @override
  State<WorkCards> createState() => _WorkCardsState();
}

class _WorkCardsState extends State<WorkCards> {
  final bool _checkvalue = false;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemExtent: 60,
      itemCount: widget.questions.length,
      itemBuilder: (context, index) {
        return Padding(
          key: ValueKey(widget.questions[index]),
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Dismissible(
            key: Key(widget.questions[index]),
            //key: UniqueKey(),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              child: const Icon(Icons.delete, color: Colors.black),
            ),
            onDismissed: (direction) {
              setState(() {
                widget.questions.removeAt(index);
                Provider.of<ServiceProvider>(context, listen: false)
                    .changequestions(widget.questions);
              });
            },
            child: Material(
              key: ValueKey(widget.questions[index]),
              child: CheckboxListTile(
                key: ValueKey(widget.questions[index]),
                tileColor: AppColor.cardColor,
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Text(
                    widget.questions[index],
                    style: AppTextStyle.valuesstyle,
                  ),
                ),
                value: _checkvalue,
                onChanged: (value) {
                  setState(() {
                    widget.complitedquetions.add(widget.questions[index]);
                    widget.questions.removeAt(index);
                    Provider.of<ServiceProvider>(context, listen: false)
                        .changequestions(widget.questions);
                    Provider.of<ServiceProvider>(context, listen: false)
                        .changecomplitedquetions(widget.complitedquetions);
                  });
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

//Карточки с ЗАВЕРШЕННЫМИ вопросами на рабочку
class ComplitedWorkCards extends StatefulWidget {
  final List<String> questions;
  final List<String> complitedquetions;
  const ComplitedWorkCards(
      {super.key, required this.complitedquetions, required this.questions});

  @override
  State<ComplitedWorkCards> createState() => _ComplitedWorkCardsState();
}

class _ComplitedWorkCardsState extends State<ComplitedWorkCards> {
  final bool _checkvalue = true;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemExtent: 60,
      itemCount: widget.complitedquetions.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Dismissible(
            key: Key(widget.complitedquetions[index]),
            //key: UniqueKey(),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              child: const Icon(Icons.delete, color: Colors.black),
            ),
            onDismissed: (direction) {
              setState(() {
                widget.complitedquetions.removeAt(index);
                Provider.of<ServiceProvider>(context, listen: false)
                    .changequestions(widget.questions);
                Provider.of<ServiceProvider>(context, listen: false)
                    .changecomplitedquetions(widget.complitedquetions);
              });
            },
            child: Material(
              child: CheckboxListTile(
                tileColor: AppColor.deleteCardColor,
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Text(
                    widget.complitedquetions[index],
                    style: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.brown,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      shadows: [
                        Shadow(
                          color: Colors.blueGrey,
                          blurRadius: 2.0,
                          offset: Offset(1.0, 0.0),
                        )
                      ],
                    ),
                  ),
                ),
                value: _checkvalue,
                onChanged: (value) {
                  setState(() {
                    widget.questions.add(widget.complitedquetions[index]);
                    widget.complitedquetions.removeAt(index);
                    Provider.of<ServiceProvider>(context, listen: false)
                        .changequestions(widget.questions);
                    Provider.of<ServiceProvider>(context, listen: false)
                        .changecomplitedquetions(widget.complitedquetions);
                  });
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
