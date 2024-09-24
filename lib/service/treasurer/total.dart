import 'package:aahelper/helper/stylemenu.dart';
import 'package:aahelper/helper/utils.dart';
import 'package:aahelper/main.dart';
import 'package:aahelper/service/treasurer/profit.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Total extends StatefulWidget {
  const Total({super.key});

  @override
  State<Total> createState() => _TotalState();
}

class _TotalState extends State<Total> {
  List<DateTime> dates = [];
  List<ProfitGroup> listProfitGroup = [];
  List<Deductions> listDeductions = [];
  DateTime? _startDate;
  DateTime? _endDate;
  ProfitGroup? totalProfit;

  @override
  void initState() {
    loadDeduction();

    super.initState();
  }

  void loadDeduction() async {
    listDeductions = await Deductions.loadDeductions();
    if (listDeductions.isNotEmpty) {
      setState(() {
        dates = getDatesFromDeductions(listDeductions);
        _startDate ??= dates[dates.length - 2];
        _endDate ??= dates.last;
        loadProfitData(_startDate!, _endDate!);
      });
    }
  }


// Загрузить отчет по запрошенным датам
  void loadProfitData(DateTime date1, DateTime date2) async {
        WorkMeetingSchedule? shedule = await WorkMeetingSchedule.loadWorkMeetingSchedule() ?? null;
    List<ProfitGroup> loadedData = await ProfitGroup.loadProfitGroups() ?? [];
    setState(() {
      listProfitGroup = loadedData.where((profitGroup) {
        return profitGroup.date.isAfter(date1) &&
                profitGroup.date.isBefore(date2) ||
            profitGroup.date.isAtSameMomentAs(date1) ||
            profitGroup.date.isAtSameMomentAs(date2);
      }).toList();
       // Удаляем последний день, если рабочки каждый день_недели номер_месяца
      if (shedule?.checkboxstatus == true) {
        listProfitGroup.removeLast();
      }
// Если рабочка совпадает с днём расчетного периода, то тоже удаляем последний день (он войдет в следующий расчетный период)
      if (shedule?.checkboxstatus == false && shedule?.dayOfMonth ==listProfitGroup.last.date.day)
      {
        listProfitGroup.removeLast();
      }
      totalProfit = ProfitGroup.totalProfit(listProfitGroup);
      Provider.of<ServiceProvider>(context, listen: false)
          .updateDates(totalProfit);
    });
  }

// Получить даты рабочек с фильтром, ограничивающим список до ближайшей рабочки
  List<DateTime> getDatesFromDeductions(List<Deductions> listdeductions) {
    DateTime currentDate = kToday;
    List<DateTime> dates = [];
    if (listdeductions.isNotEmpty) {
      for (var deduction in listdeductions) {
        dates.add(deduction.date);
      }
      DateTime targetDate = dates.firstWhere(
          (date) => date.isAfter(currentDate),
          orElse: () => dates.last);

      int startIndex = dates.indexOf(dates.first);
      int endIndex =
          dates.indexOf(targetDate); // конечная дата - следующая за текущей
// Проверем, если текущая дата совпадает с датой списка, то конечная дата - текущая.
      if (compareDate(dates[endIndex - 1], currentDate)) {
        endIndex = endIndex - 1;
      }

      List<DateTime> filteredDates = dates.sublist(startIndex, endIndex + 1);

      return filteredDates;
    } else {
      return [];
    }
  }

  String _formatDate(DateTime date) {
    return date.toLocal().toIso8601String().split('T')[0];
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
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Выберите отчетный период',
                  style: AppTextStyle.menutextstyle,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text(
                      'От',
                      style: AppTextStyle.menutextstyle,
                    ),
                    DropdownButton<DateTime>(
                      hint: Text(_formatDate(_startDate!)),
                      value: _startDate,
                      onChanged: (DateTime? newValue) {
                        setState(() {
                          _startDate = newValue;
                          if (_endDate != null &&
                              _startDate!.isAfter(_endDate!)) {
                            _endDate = _startDate;
                          }
                          loadProfitData(_startDate!, _endDate!);
                          Provider.of<ServiceProvider>(context, listen: false)
                              .updateDates(totalProfit);
                        });
                      },
                      items: dates
                          .where((date) =>
                              _endDate == null || date.isBefore(_endDate!))
                          .map((DateTime date) {
                        return DropdownMenuItem<DateTime>(
                          value: date,
                          child: Text(_formatDate(date)),
                        );
                      }).toList(),
                    ),
                    const Text(
                      'До',
                      style: AppTextStyle.menutextstyle,
                    ),
                    DropdownButton<DateTime>(
                      hint: Text(_formatDate(_endDate!)),
                      value: _endDate,
                      onChanged: (DateTime? newValue) {
                        setState(() {
                          _endDate = newValue;
                          if (_startDate != null &&
                              _endDate!.isBefore(_startDate!)) {
                            _startDate = _endDate;
                          }
                          loadProfitData(_startDate!, _endDate!);

                          Provider.of<ServiceProvider>(context, listen: false)
                              .updateDates(totalProfit!);
                        });
                      },
                      items: dates
                          .where((date) =>
                              _startDate == null || date.isAfter(_startDate!))
                          .map((DateTime date) {
                        return DropdownMenuItem<DateTime>(
                          value: date,
                          child: Text(_formatDate(date)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                TotalProfitCard(
                  listDeductions: listDeductions,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '*Отчёт учитывает ТОЛЬКО баланс за выбранный период без остатков с прошлых периодов и резерва',
                    style: AppTextStyle.spantextstyle,
                    softWrap: true,
                  ),
                ),
              ],
            ),
          );
  }
}

// Итоговая карточка
class TotalProfitCard extends StatefulWidget {
  final List<Deductions> listDeductions;
  const TotalProfitCard({super.key, required this.listDeductions});

  @override
  State<TotalProfitCard> createState() => _TotalProfitCardState();
}

class _TotalProfitCardState extends State<TotalProfitCard> {
  bool _isExpanded = false;
  ProfitGroup? _totalProfit;
  double? sevenTraditioncash;
  double? sevenTraditioncard;
  double? profitliteratura;
  double? profitother;

  double? expensiveliteratura;
  double? tea;
  double? medal;
  double? postmail;
  double? expensiveother;

  late List<Deductions> _listdeductions;
  // double? balance;
  // double? reserve;
  double? anniversary;

  @override
  void initState() {
    _listdeductions = widget.listDeductions;
    // balance = _listdeductions[_listdeductions.length - 1].balance ?? 0;
    // reserve = _listdeductions[_listdeductions.length - 1].reserve ?? 0;
    anniversary = _listdeductions[_listdeductions.length - 1].anniversary ?? 0;

    super.initState();
  }

  @override
  void didChangeDependencies() {
    _totalProfit =
        Provider.of<ServiceProvider>(context, listen: true).totalProfit!;
    super.didChangeDependencies();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  double _calculateProfit() {
    if (_totalProfit != null) {
      return (_totalProfit?.sevenTraditioncash ?? 0) +
          (_totalProfit?.sevenTraditioncard ?? 0) +
          (_totalProfit?.profitliteratura ?? 0) +
          (_totalProfit?.profitother ?? 0);
    } else {
      return 0.0;
    }
  }

  double _calculateConsumption() {
    return (_totalProfit?.expensiveliteratura ?? 0) +
        (_totalProfit?.tea ?? 0) +
        (_totalProfit?.medal ?? 0) +
        (_totalProfit?.postmail ?? 0) +
        (_totalProfit?.expensiveother ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6.0),
      child: Card(
        elevation: 5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              color: AppColor.cardColor,
              child: ListTile(
                title: Column(
                  children: [
                    Text(
                      'Собрано за период: ${_calculateProfit()}',
                      style: AppTextStyle.valuesstyle,
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      'Потрачено за период: ${_calculateConsumption()}',
                      style: AppTextStyle.valuesstyle,
                    ),
                    Text(
                      'Юбилей: ${_totalProfit?.profitjubiley}',
                      style: AppTextStyle.valuesstyle,
                    ),
                  ],
                ),
                trailing: _isExpanded
                    ? const Icon(Icons.expand_less)
                    : const Icon(Icons.expand_more),
                onTap: () {
                  _toggleExpanded();
                },
              ),
            ),
            _isExpanded
                ? Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: MediaQuery.of(context).size.height * 0.24,
                    color: AppColor.defaultColor,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: ProfitTextWidget(
                              profitGroup: _totalProfit!,
                            ),
                          ),
                          Expanded(
                            child:
                                ExpensiveTextWidget(profitGroup: _totalProfit!),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(),
            TotalChartWidget(
              profitGroup: _totalProfit!,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 14.0),
              child: Text(
                'ИТОГО за выбранный период: ${(_calculateProfit() - _calculateConsumption()).toStringAsFixed(2)}', // + balance
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Диаграмма
class TotalChartWidget extends StatelessWidget {
  final ProfitGroup profitGroup;
  const TotalChartWidget({super.key, required this.profitGroup});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          centerSpaceRadius: 0,
          sections: [
            PieChartSectionData(
                color: Colors.blue,
                value: profitGroup.sevenTraditioncash! +
                    profitGroup.sevenTraditioncard!,
                title: '7 традиция',
                radius: 130,
                titleStyle: AppTextStyle.valuesstyle),
            PieChartSectionData(
              color: Colors.green,
              value: profitGroup.profitliteratura,
              title: 'Продажа литература',
              radius: 130,
              titleStyle: AppTextStyle.valuesstyle,
              titlePositionPercentageOffset: 0.8,
            ),
            PieChartSectionData(
                color: Colors.grey,
                value: profitGroup.profitother,
                title: 'Доход другое',
                radius: 130,
                titleStyle: AppTextStyle.valuesstyle),
            PieChartSectionData(
              color: Colors.orange,
              value: profitGroup.expensiveliteratura,
              title: 'Покупка книги',
              radius: 130,
              titleStyle: AppTextStyle.valuesstyle,
              titlePositionPercentageOffset: 0.7,
            ),
            PieChartSectionData(
                color: Colors.yellow,
                value: profitGroup.tea,
                title: 'Чай',
                radius: 130,
                titleStyle: AppTextStyle.valuesstyle),
            PieChartSectionData(
                color: Colors.pink,
                value: profitGroup.medal,
                title: 'Медали',
                radius: 130,
                titleStyle: AppTextStyle.valuesstyle),
            PieChartSectionData(
                color: Colors.white,
                value: profitGroup.postmail,
                title: 'Открытки',
                radius: 130,
                titleStyle: AppTextStyle.valuesstyle),
            PieChartSectionData(
                color: Colors.orange,
                value: profitGroup.expensiveother,
                title: 'Иное затраты',
                radius: 130,
                titleStyle: AppTextStyle.valuesstyle),
          ],
        ),
      ),
    );
  }
}
