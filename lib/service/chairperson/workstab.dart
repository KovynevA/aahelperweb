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
  DateTime? selectedDate;
  List<DateTime>? dates;
  List<ProtocolWorkMeeting> protocols = [];
  String? otherQuestion;

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
        //selectedDate = dates?.last ?? kToday;
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

  Future<void> showProtocol(context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return MeetingDialog(selectedDate: selectedDate!);
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
        List<String>? questions = serviceProvider.questions;
        List<String>? complitedquetions = serviceProvider.completedquetions;

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
              maxHeight: MediaQuery.of(context).size.height * 0.6,
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
                  dates == null
                      ? Container()
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColor.defaultColor,
                            border: Border.all(color: Colors.black38, width: 3),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: <BoxShadow>[
                              //apply shadow on Dropdown button
                              BoxShadow(
                                  color: Color.fromRGBO(
                                      0, 0, 0, 0.57), //shadow for button
                                  blurRadius: 5) //blur radius of shadow
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.only(left: 30, right: 30),
                            child: DropdownButton<DateTime>(
                              underline: Container(),
                              style: AppTextStyle.valuesstyle,
                              hint: Text(
                                'Протоколы',
                                style: AppTextStyle.valuesstyle,
                              ),
                              value: selectedDate,
                              onChanged: (DateTime? newValue) {
                                setState(() {
                                  selectedDate = newValue!;
                                });
                                showProtocol(context);
                              },
                              items: dates?.map((DateTime date) {
                                return DropdownMenuItem<DateTime>(
                                  value: date,
                                  child: Text(_formatDate(date)),
                                );
                              }).toList(),
                            ),
                          ),
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

// Диалоговое окно с рабочкой
class MeetingDialog extends StatefulWidget {
  final DateTime selectedDate;

  MeetingDialog({required this.selectedDate});

  @override
  _MeetingDialogState createState() => _MeetingDialogState();
}

class _MeetingDialogState extends State<MeetingDialog> {
  List<ProtocolWorkMeeting>? protocols;
  ProtocolWorkMeeting? protocol;
  List<Map<String, Answers>> votes = [{}];
  TextEditingController quorumController = TextEditingController();
  List<TextEditingController> questionControllers = [TextEditingController()];
  List<TextEditingController> supportControllers = [TextEditingController()];
  List<TextEditingController> againstControllers = [TextEditingController()];
  List<TextEditingController> abstainedControllers = [TextEditingController()];
  TextEditingController additionalInfoController = TextEditingController();

  @override
  void initState() {
    loadProtocolsWorkMeeting();

    super.initState();
  }

  void loadProtocolsWorkMeeting() async {
    protocols = await ProtocolWorkMeeting.loadProtocolWorkMeeting();
    if (protocols != null) {
      ProtocolWorkMeeting? foundProtocol =
          findProtocolWorkMeetingByDate(widget.selectedDate);
      setState(() {
        protocol = foundProtocol;
        quorumController =
            TextEditingController(text: protocol?.quorum.toString());
        questionControllers.clear();
        supportControllers.clear();
        againstControllers.clear();
        abstainedControllers.clear();
        additionalInfoController = TextEditingController(text: protocol?.text);

        if (protocol != null) {
          for (int i = 0; i < protocol!.vote.length; i++) {
            questionControllers
                .add(TextEditingController(text: protocol!.vote[i].keys.first));
            supportControllers.add(TextEditingController(
                text: protocol!.vote[i].values.first.support.toString()));
            againstControllers.add(TextEditingController(
                text: protocol!.vote[i].values.first.against.toString()));
            abstainedControllers.add(TextEditingController(
                text: protocol!.vote[i].values.first.abstained.toString()));
          }
        }
      });
    }
  }

// Поиск протокола по дате
  ProtocolWorkMeeting? findProtocolWorkMeetingByDate(DateTime date) {
    for (ProtocolWorkMeeting protocol in protocols!) {
      if (compareDate(protocol.date, date)) {
        return protocol;
      }
    }
    return null; // Возвращаем null, если не найдено совпадений
  }

  void addVote() {
    setState(() {
      votes.add({});
      questionControllers.add(TextEditingController(text: ''));
      supportControllers.add(TextEditingController(text: ''));
      againstControllers.add(TextEditingController(text: ''));
      abstainedControllers.add(TextEditingController(text: ''));
    });
  }

  void removeVote() {
    setState(() {
      // if (questionControllers.length > 1) {
      votes.removeLast();
      questionControllers.removeLast();
      supportControllers.removeLast();
      againstControllers.removeLast();
      abstainedControllers.removeLast();
      //   }
    });
  }

  @override
  void dispose() {
    quorumController.dispose();
    for (var controller in questionControllers) {
      controller.dispose();
    }
    for (var controller in supportControllers) {
      controller.dispose();
    }
    for (var controller in againstControllers) {
      controller.dispose();
    }
    for (var controller in abstainedControllers) {
      controller.dispose();
    }
    additionalInfoController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return date.toLocal().toIso8601String().split('T')[0];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColor.backgroundColor,
      shadowColor: Colors.black,
      elevation: 8.0,
      insetPadding: EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Дата собрания: ${_formatDate(widget.selectedDate)}',
                style: AppTextStyle.menutextstyle,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    'Кворум',
                    style: AppTextStyle.valuesstyle,
                  ),
                  TextFieldStyleWidget(
                    controller: quorumController,
                    sizewidth: 50,
                  ),
                  IconButton(
                    onPressed: addVote,
                    icon: const Icon(Icons.add_box),
                  ),
                  IconButton(
                    onPressed: removeVote,
                    icon: const Icon(Icons.remove_circle),
                  ),
                ],
              ),
              SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                itemCount: questionControllers.length,
                itemBuilder: (context, index) {
                  int support = supportControllers[index].text.isNotEmpty
                      ? int.parse(supportControllers[index].text)
                      : 0;
                  int against = againstControllers[index].text.isNotEmpty
                      ? int.parse(againstControllers[index].text)
                      : 0;
                  int abstained = abstainedControllers[index].text.isNotEmpty
                      ? int.parse(abstainedControllers[index].text)
                      : 0;
                  String isDecisionMade = 'Не принято';
                  if (abstained >= support) {
                    isDecisionMade = 'Не принято';
                  } else if (support > against) {
                    isDecisionMade = 'Принято';
                  } else
                    isDecisionMade = 'Не принято';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Вопрос на голосование № ${index + 1}',
                          style: AppTextStyle.menutextstyle,
                        ),
                      ),
                      TextFieldStyleWidget(
                        // text: 'Вопрос на голосование № ${index + 1}',
                        controller: questionControllers[index],
                        decoration: Decor.decorTextField,
                        sizewidth: double.infinity,
                      ),
                      SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Text(
                                'За',
                                style: AppTextStyle.valuesstyle,
                              ),
                              TextFieldStyleWidget(
                                decoration: Decor.decorTextField,
                                controller: supportControllers[index],
                                sizewidth: 50,
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                'Против',
                                style: AppTextStyle.valuesstyle,
                              ),
                              TextFieldStyleWidget(
                                decoration: Decor.decorTextField,
                                controller: againstControllers[index],
                                sizewidth: 50,
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                'Воздержался',
                                style: AppTextStyle.valuesstyle,
                              ),
                              TextFieldStyleWidget(
                                decoration: Decor.decorTextField,
                                controller: abstainedControllers[index],
                                sizewidth: 50,
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Решение: $isDecisionMade',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  );
                },
              ),
              Center(
                child: Text(
                  'Дополнительная информация',
                  style: AppTextStyle.menutextstyle,
                ),
              ),
              TextFieldStyleWidget(
                decoration: Decor.decorTextField,
                controller: additionalInfoController,
                sizewidth: double.infinity,
              ),
              SizedBox(height: 10),
              TextButton(
                style: AppButtonStyle.iconButton,
                onPressed: () {
                  // Сохранение данных в переменную ProtocolWorkMeeting protocol
                  List<Map<String, Answers>> votesData = [];
                  for (int i = 0; i < questionControllers.length; i++) {
                    Answers answers = Answers(
                      support: supportControllers[i].text.isNotEmpty
                          ? int.parse(supportControllers[i].text)
                          : 0,
                      against: againstControllers[i].text.isNotEmpty
                          ? int.parse(againstControllers[i].text)
                          : 0,
                      abstained: abstainedControllers[i].text.isNotEmpty
                          ? int.parse(abstainedControllers[i].text)
                          : 0,
                    );

                    Map<String, Answers> voteData = {
                      questionControllers[i].text: answers,
                    };
                    votesData.add(voteData);
                  }

                  ProtocolWorkMeeting updatedProtocol = ProtocolWorkMeeting(
                    date: widget.selectedDate,
                    quorum: quorumController.text.isNotEmpty
                        ? int.parse(quorumController.text)
                        : 0,
                    vote: votesData,
                    text: additionalInfoController.text,
                  );

                  // Вызов метода для сохранения данных в Firestore
                  ProtocolWorkMeeting.saveProtocolWorkMeeting(updatedProtocol);
                  Navigator.of(context).pop();
                },
                child: Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
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
