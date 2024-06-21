import 'package:aahelper/helper/stylemenu.dart';
import 'package:aahelper/service/leading/clockpicker/clockpicker.dart';
import 'package:flutter/material.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  double _peopleSliderValue = 10;
  double _timeSliderValue = 45;
  double _timespeak = 0;
  Time? selectedTime;
  bool automatTime = false;

  late Time time;
  late int hour;
  late int min;
  late int sec;

  @override
  void initState() {
    getSelectedTime();
    time = selectedTime!;
    hour = time.hour;
    min = time.min;
    sec = time.sec;
    super.initState();
  }

  Time getValueTime() {
    return time = Time(hour: hour, min: min, sec: sec);
  }

  void getSelectedTime() {
    _peopleSliderValue = _peopleSliderValue.round().toDouble();
    _timeSliderValue = _timeSliderValue.round().toDouble();
    _timespeak = ((_timeSliderValue - 5) / _peopleSliderValue).roundToDouble();

    setState(() {
      !automatTime
          ? selectedTime = Time(
              hour: (_timespeak / 60).floor(),
              min: (_timespeak % 60).floor(),
              sec: 0)
          : selectedTime = getValueTime();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Text(
            'Присутствует на группе: $_peopleSliderValue',
            style: AppTextStyle.valuesstyle,
          ),
          SliderPeople(
            value: _peopleSliderValue,
            onChanged: (value) {
              setState(() {
                _peopleSliderValue = value;
                getSelectedTime();
              });
            },
          ),
          Text(
            'Осталось время на высказывание: $_timeSliderValue',
            style: AppTextStyle.valuesstyle,
          ),
          SliderTime(
            value: _timeSliderValue,
            onChanged: (value) {
              setState(() {
                _timeSliderValue = value;
                getSelectedTime();
              });
            },
          ),
          Text(
            'Время на одно высказавание примерно: $_timespeak',
            style: AppTextStyle.spantextstyle,
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  textAlign: TextAlign.center,
                  'Автоматическое время?',
                  style: AppTextStyle.valuesstyle,
                ),
              ),
              Switch(
                value: automatTime,
                activeColor: Colors.red,
                onChanged: (bool value) {
                  setState(() {
                    automatTime = value;
                  });
                },
              ),
              const Expanded(
                child: Text(
                  textAlign: TextAlign.center,
                  'Установить вручную?',
                  style: AppTextStyle.valuesstyle,
                ),
              ),
            ],
          ),
          ClockPicker(
            time: selectedTime!,
            automatTime: automatTime,
          ),
        ],
      ),
    );
  }
}

class SliderPeople extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const SliderPeople({super.key, required this.value, required this.onChanged});

  @override
  State<SliderPeople> createState() => _SliderPeopleState();
}

class _SliderPeopleState extends State<SliderPeople> {
  @override
  Widget build(BuildContext context) {
    return Slider(
      value: widget.value,
      max: 50,
      divisions: 50,
      label: widget.value.round().toString(),
      onChanged: widget.onChanged,
    );
  }
}

class SliderTime extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const SliderTime({super.key, required this.value, required this.onChanged});

  @override
  State<SliderTime> createState() => _SliderTimeState();
}

class _SliderTimeState extends State<SliderTime> {
  @override
  Widget build(BuildContext context) {
    return Slider(
      value: widget.value,
      max: 120,
      divisions: 24,
      label: widget.value.round().toString(),
      onChanged: widget.onChanged,
    );
  }
}
