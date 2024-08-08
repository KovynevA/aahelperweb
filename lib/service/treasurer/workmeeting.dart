import 'package:aahelper/helper/stylemenu.dart';
import 'package:aahelper/helper/utils.dart';
import 'package:flutter/material.dart';

class WorkMeeting extends StatefulWidget {
  const WorkMeeting({super.key});

  @override
  State<WorkMeeting> createState() => _WorkMeetingState();
}

class _WorkMeetingState extends State<WorkMeeting> {
  List<DateTime> dates = [];
  List<ProfitGroup> listProfitGroup = [];
  List<Deductions> listDeductions = [];
  ProfitGroup? totalProfit;
  DateTime? _startDate;
  double? totalfreecash;
  List<ProfitGroup>? loadedData;

  @override
  void initState() {
    _startDate = kFirstDay;
    loadDeductions();

    super.initState();
  }

// Лист со всеми рабочками
  void loadDeductions() async {
    loadedData = await ProfitGroup.loadProfitGroups();
    listDeductions = await Deductions.loadDeductions();
    if (listDeductions.isNotEmpty) {
      setState(() {
        // даты для комбобокса со всеми рабочками до сегодня
        dates = getDatesFromDeductions(listDeductions);
        // Последняя дата
        _startDate = dates.last;
        // Загружаем
        loadProfitData(_startDate!, dates[dates.indexOf(_startDate!) - 1]);
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

// Загрузить отчет по запрошенным датам
  void loadProfitData(DateTime date2, DateTime date1) {
    if (loadedData != null) {
      setState(() {
        listProfitGroup = loadedData!.where((profitGroup) {
          return profitGroup.date.isAfter(date1) &&
                  profitGroup.date.isBefore(date2) ||
              profitGroup.date.isAtSameMomentAs(date1) ||
              profitGroup.date.isAtSameMomentAs(date2);
        }).toList();
      });
      listProfitGroup.removeLast();
      totalProfit = ProfitGroup.totalProfit(listProfitGroup);
      _totalFreeCash();
    }
  }

  String _formatDate(DateTime date) {
    return date.toLocal().toIso8601String().split('T')[0];
  }

  double _calculateProfit() {
    if (totalProfit != null) {
      return (totalProfit?.sevenTraditioncash ?? 0) +
          (totalProfit?.sevenTraditioncard ?? 0) +
          (totalProfit?.profitliteratura ?? 0) +
          (totalProfit?.profitother ?? 0);
    } else {
      return 0.0;
    }
  }

  double _calculateConsumption() {
    return (totalProfit?.expensiveliteratura ?? 0) +
        (totalProfit?.tea ?? 0) +
        (totalProfit?.medal ?? 0) +
        (totalProfit?.postmail ?? 0) +
        (totalProfit?.expensiveother ?? 0);
  }

  void _totalFreeCash() {
    totalfreecash = (_calculateProfit() +
        (listDeductions[dates.indexOf(_startDate!) - 1].balance ?? 0) -
        _calculateConsumption());
  }

  @override
  Widget build(BuildContext context) {
    return (dates.isEmpty || listProfitGroup.isEmpty)
        ? const Center(
            child: Text(
              'Нет данных для отображения',
              style: AppTextStyle.menutextstyle,
            ),
          )
        : SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const Text(
                      'Рабочее собрание: ',
                      style: AppTextStyle.valuesstyle,
                    ),
                    DropdownButton<DateTime>(
                      hint: Text(_formatDate(_startDate!)),
                      value: _startDate,
                      onChanged: (DateTime? newValue) {
                        setState(() {
                          _startDate = newValue!;
                          loadProfitData(_startDate!,
                              dates[dates.indexOf(_startDate!) - 1]);
                        });
                      },
                      items: dates.map((DateTime date) {
                        return DropdownMenuItem<DateTime>(
                          value: date,
                          child: Text(_formatDate(date)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                ContainerForWorkMeetings(
                  child: Column(
                    children: [
                      Text(
                        'Доход за выбранный период = ${_calculateProfit()}',
                        style: AppTextStyle.valuesstyle,
                      ),
                      Text(
                        'Расход за выбранный период = ${_calculateConsumption()}',
                        style: AppTextStyle.valuesstyle,
                      ),
                    ],
                  ),
                ),
                ContainerForWorkMeetings(
                  child: Column(
                    children: [
                      Text(
                        'Остаток = ${(listDeductions[dates.indexOf(_startDate!) - 1].balance ?? 0).toStringAsFixed(2)}',
                        style: AppTextStyle.valuesstyle,
                      ),
                      Text(
                        'Резерв = ${listDeductions[dates.indexOf(_startDate!) - 1].reserve ?? 0}',
                        style: AppTextStyle.valuesstyle,
                      ),
                      Text(
                        'Юбилей = ${listDeductions[dates.indexOf(_startDate!) - 1].anniversary ?? 0}',
                        style: AppTextStyle.valuesstyle,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Text(
                    'ИТОГО свободные средства: ${(totalfreecash ?? 0).toStringAsFixed(2)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                GetWorkMeetingWidget(
                    indexdeduction: dates.indexOf(_startDate!),
                    totalfreecash: totalfreecash ?? 0,
                    listdeductions: listDeductions),
              ],
            ),
          );
  }
}

// Провести рабочку
class GetWorkMeetingWidget extends StatefulWidget {
  final int indexdeduction;
  final double totalfreecash;
  final List<Deductions> listdeductions;
  const GetWorkMeetingWidget({
    super.key,
    required this.totalfreecash,
    required this.indexdeduction,
    required this.listdeductions,
  });

  @override
  State<GetWorkMeetingWidget> createState() => _GetWorkMeetingWidgetState();
}

class _GetWorkMeetingWidgetState extends State<GetWorkMeetingWidget> {
  TextEditingController reserveController = TextEditingController();
  TextEditingController anniversaryController = TextEditingController();
  TextEditingController rentController = TextEditingController();
  TextEditingController rcController = TextEditingController();
  TextEditingController rsoController = TextEditingController();
  TextEditingController mosfondController = TextEditingController();
  TextEditingController fivetraditionController = TextEditingController();
  late Deductions deduction;
  late Deductions prevdeduction;
  bool checkboxpercent = false;
  ServiceUser? serviceuser;

  @override
  void initState() {
    super.initState();
    deduction = widget.listdeductions[widget.indexdeduction];
    prevdeduction = widget.listdeductions[widget.indexdeduction - 1];
    reserveController = TextEditingController(
        text: (deduction.reserve ?? prevdeduction.reserve ?? 0).toString());
    anniversaryController = TextEditingController(
        text: (deduction.anniversary ?? prevdeduction.anniversary ?? 0)
            .toString());
    rentController = TextEditingController(
        text: (deduction.rent ?? prevdeduction.rent ?? 0).toString());
    rcController =
        TextEditingController(text: (deduction.rc ?? 0).toStringAsFixed(2));
    rsoController =
        TextEditingController(text: (deduction.rso ?? 0).toStringAsFixed(2));
    mosfondController = TextEditingController(
        text: (deduction.mosfond ?? 0).toStringAsFixed(2));
    fivetraditionController = TextEditingController(
        text: (deduction.fivetradition ?? 0).toStringAsFixed(2));
    getServiceUser();
  }

  @override
  void dispose() {
    reserveController.dispose();
    anniversaryController.dispose();
    rentController.dispose();
    rcController.dispose();
    rsoController.dispose();
    mosfondController.dispose();
    fivetraditionController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GetWorkMeetingWidget oldWidget) {
    if (widget.indexdeduction != oldWidget.indexdeduction) {
      setState(() {
        deduction = widget.listdeductions[widget.indexdeduction];
        prevdeduction = widget.listdeductions[widget.indexdeduction - 1];
        reserveController = TextEditingController(
            text: (deduction.reserve ?? prevdeduction.reserve ?? 0).toString());
        anniversaryController = TextEditingController(
            text: (deduction.anniversary ?? prevdeduction.anniversary ?? 0)
                .toString());
        rentController = TextEditingController(
            text: (deduction.rent ?? prevdeduction.rent ?? 0).toString());
        rcController =
            TextEditingController(text: (deduction.rc ?? 0).toStringAsFixed(2));
        rsoController = TextEditingController(
            text: (deduction.rso ?? 0).toStringAsFixed(2));
        mosfondController = TextEditingController(
            text: (deduction.mosfond ?? 0).toStringAsFixed(2));
        fivetraditionController = TextEditingController(
            text: (deduction.fivetradition ?? 0).toStringAsFixed(2));
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  void getServiceUser() async {
    if (isAutorization) {
      serviceuser =
          await ServiceUser.getServiceUserFromFirestore(currentUser!.email!);
    }
  }

// Провести рабочее собрание
  void holdWokMeeting() {
    deduction.reserve = double.parse(
        reserveController.text != '' ? reserveController.text : '0');
    deduction.anniversary = double.parse(
        anniversaryController.text != '' ? anniversaryController.text : '0');
    deduction.rent =
        double.parse(rentController.text != '' ? rentController.text : '0');

    //Если резерв прошлого месяца не равен установленному резерву, то считаем разницу
    final differencereserv = deduction.reserve != prevdeduction.reserve
        ? (deduction.reserve ?? 0) - (prevdeduction.reserve ?? 0)
        : 0; // иначе разница ноль

    final total = (widget.totalfreecash) -
        (deduction.rent ?? 0) -
        differencereserv -
        (deduction.anniversary ?? 0);

    // Если считать не в процентах
    if (!checkboxpercent) {
      deduction.rc =
          double.parse(rcController.text != '' ? rcController.text : '0');
      deduction.rso =
          double.parse(rsoController.text != '' ? rsoController.text : '0');
      deduction.mosfond = double.parse(
          mosfondController.text != '' ? mosfondController.text : '0');
      deduction.fivetradition = double.parse(fivetraditionController.text != ''
          ? fivetraditionController.text
          : '0');
      // Если в процентах
    } else {
      deduction.rc = (total / 100) *
          (double.parse(rcController.text != '' ? rcController.text : '0'));
      deduction.rso = (total / 100) *
          (double.parse(rsoController.text != '' ? rsoController.text : '0'));
      deduction.mosfond = (total / 100) *
          (double.parse(
              mosfondController.text != '' ? mosfondController.text : '0'));
      deduction.fivetradition = (total / 100) *
          (double.parse(fivetraditionController.text != ''
              ? fivetraditionController.text
              : '0'));
    }

    deduction.balance = (total) -
        ((deduction.rc ?? 0) +
            (deduction.rso ?? 0) +
            (deduction.mosfond ?? 0) +
            (deduction.fivetradition ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ContainerForWorkMeetings(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Резерв: ',
                    style: AppTextStyle.valuesstyle,
                  ),
                  TextFieldStyleWidget(
                    decoration: Decor.decorTextField,
                    sizeheight: 30,
                    controller: reserveController,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Юбилей: ',
                    style: AppTextStyle.valuesstyle,
                  ),
                  TextFieldStyleWidget(
                    decoration: Decor.decorTextField,
                    sizeheight: 30,
                    controller: anniversaryController,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Аренда: ',
                    style: AppTextStyle.valuesstyle,
                  ),
                  TextFieldStyleWidget(
                    decoration: Decor.decorTextField,
                    sizeheight: 30,
                    controller: rentController,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'В % от остатка?',
                    style: AppTextStyle.valuesstyle,
                  ),
                  Checkbox(
                    value: checkboxpercent,
                    onChanged: (bool? newvalue) {
                      setState(() {
                        checkboxpercent = newvalue!;
                      });
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Районный комитет: ',
                    style: AppTextStyle.valuesstyle,
                  ),
                  TextFieldStyleWidget(
                    decoration: Decor.decorTextField,
                    sizeheight: 30,
                    controller: rcController,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'РСО: ',
                    style: AppTextStyle.valuesstyle,
                  ),
                  TextFieldStyleWidget(
                    decoration: Decor.decorTextField,
                    sizeheight: 30,
                    controller: rsoController,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Московский Фонд: ',
                    style: AppTextStyle.valuesstyle,
                  ),
                  TextFieldStyleWidget(
                    decoration: Decor.decorTextField,
                    sizeheight: 30,
                    controller: mosfondController,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '5 традиция: ',
                    style: AppTextStyle.valuesstyle,
                  ),
                  TextFieldStyleWidget(
                    decoration: Decor.decorTextField,
                    sizeheight: 30,
                    controller: fivetraditionController,
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Text(
            'Остаток на следующий месяц: ${(deduction.balance ?? 0).toStringAsFixed(2)}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        ElevatedButton(
          style: AppButtonStyle.dialogButton,
          onPressed: () {
            (serviceuser!.type.contains(ServiceName.chairperson) ||
                    serviceuser!.type.contains(ServiceName.treasurer))
                ? setState(() {
                    holdWokMeeting();
                    widget.listdeductions[widget.indexdeduction] = deduction;
                    Deductions.saveDeductions(widget.listdeductions);
                    checkboxpercent = false;
                    infoSnackBar(context, 'Рабочее собрание сохранено');
                  })
                : infoSnackBar(context, 'Недостаточно прав');
          },
          child: const Text('Провести рабочку'),
        ),
      ],
    );
  }
}

class ContainerForWorkMeetings extends StatelessWidget {
  final Widget child;
  const ContainerForWorkMeetings({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColor.cardColor,
        border: Border.all(width: 1.3, color: Colors.black),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade600, spreadRadius: 1, blurRadius: 15)
        ],
      ),
      child: child,
    );
  }
}
