import 'dart:async';

import 'package:aahelper/helper/stylemenu.dart';
import 'package:aahelper/service/leading/clockpicker/clockstyle.dart';
import 'package:aahelper/service/leading/clockpicker/hours.dart';
import 'package:aahelper/service/leading/clockpicker/minutes.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class ClockPicker extends StatefulWidget {
  final Time time;
  final bool automatTime;
  const ClockPicker({
    required this.time,
    required this.automatTime,
  }) : super(key: const PageStorageKey<String>('ClockPicker'));

  @override
  State<ClockPicker> createState() => _ClockPickerState();
}

class _ClockPickerState extends State<ClockPicker>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late Time time;
  late int hour;
  late int min;
  late int sec;

  FixedExtentScrollController scrollControllerHours =
      FixedExtentScrollController();
  FixedExtentScrollController scrollControllerMinutes =
      FixedExtentScrollController();
  FixedExtentScrollController scrollControllerSeconds =
      FixedExtentScrollController();

  bool isCountingDown = false;
  Timer? timer;

  final player = AudioPlayer();

  @override
  void initState() {
    if (!isCountingDown) {
      time = widget.time;
      hour = time.hour;
      min = time.min;
      sec = time.sec;
      scrollControllerHours = FixedExtentScrollController(initialItem: hour);
      scrollControllerMinutes = FixedExtentScrollController(initialItem: min);
      scrollControllerSeconds = FixedExtentScrollController(initialItem: sec);
    }
    super.initState();
  }

  @override
  void didUpdateWidget(ClockPicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    if ((widget.time != oldWidget.time) ||
        (widget.automatTime != oldWidget.automatTime)) {
      time = widget.time;
      hour = time.hour;
      min = time.min;
      sec = time.sec;

      scrollControllerHours.jumpToItem(hour);
      scrollControllerMinutes.jumpToItem(min);
      scrollControllerSeconds.jumpToItem(sec);
    }
  }

// Запуск таймера
  void startStopTimer() {
    if (isCountingDown) {
      timer?.cancel();

      isCountingDown = false;
    } else {
      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        updateSeconds(sec - 1);
      });

      isCountingDown = true;
    }
    setState(() {});
    if (time == const Time(hour: 0, min: 0, sec: 0)) {}
  }

// Обновление секунд
  void updateSeconds(int value) async {
    sec = value;
    if (sec < 0) {
      sec = 59;
      updateMinutes(min - 1);
    }
    updateClockTime();
    scrollControllerSeconds.jumpToItem(sec);

    if (hour == 0 && min == 0 && sec == 0) {
      isCountingDown = false;
      timer?.cancel();
      // setState(() {});
      // Воспроизводим звук
      await player.play(
        AssetSource('audio/melodiya.mp3'),
      );
    }
  }

// Обновление минут
  void updateMinutes(int value) {
    min = value;
    if (min < 0) {
      min = 59;
      updateHours(hour - 1);
    }
    updateClockTime();
    scrollControllerMinutes.jumpToItem(min);
  }

// Обновление часов
  void updateHours(int value) {
    hour = value;
    if (hour < 0) {
      hour = 0;
    }
    updateClockTime();
    scrollControllerHours.jumpToItem(hour);
  }

// Обновление переменной времени
  void updateClockTime() {
    time = Time(hour: hour, min: min, sec: sec);
  }

  @override
  void dispose() {
    scrollControllerSeconds.dispose();
    scrollControllerMinutes.dispose();
    scrollControllerHours.dispose();

    if (isCountingDown) {
      timer?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border.all(width: 9.0, color: Colors.white),
              shape: BoxShape.circle,
              image: const DecorationImage(
                image: AssetImage('assets/images/time.jpg'),
              ),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black45,
                    offset: Offset(1, 2),
                    blurRadius: 2.3,
                    blurStyle: BlurStyle.solid),
              ],
            ),
            height: MediaQuery.of(context).size.height * 0.5,
            width: MediaQuery.of(context).size.width * 0.9,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LoopingListView(
                  scrollController: scrollControllerHours,
                  onSelected: (int value) {
                    hour = value;
                    updateClockTime();
                  },
                  isScrollEnabled: widget.automatTime,
                  children: List<Widget>.generate(
                    13,
                    (index) => MyHours(hours: index),
                  ),
                ),
                dotText,
                //minutes wheel
                LoopingListView(
                  scrollController: scrollControllerMinutes,
                  onSelected: (int value) {
                    min = value;
                    updateClockTime();
                  },
                  isScrollEnabled: widget.automatTime,
                  children: List<Widget>.generate(
                    60,
                    (index) => MyMinutes(mins: index),
                  ),
                ),
                dotText,
                //seconds wheel
                LoopingListView(
                  scrollController: scrollControllerSeconds,
                  onSelected: (int value) {
                    sec = value;
                    updateClockTime();
                  },
                  isScrollEnabled: widget.automatTime,
                  children: List<Widget>.generate(
                    60,
                    (index) => MyMinutes(mins: index),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  startStopTimer();
                },
                style: AppButtonStyle.dialogButton,
                child: Text(
                  isCountingDown ? 'Остановить' : 'Запустить',
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    time = widget.time;
                    hour = time.hour;
                    min = time.min;
                    sec = time.sec;

                    scrollControllerHours.jumpToItem(hour);
                    scrollControllerMinutes.jumpToItem(min);
                    scrollControllerSeconds.jumpToItem(sec);
                    isCountingDown = true;
                    startStopTimer();
                    player.stop();
                  });
                },
                style: AppButtonStyle.dialogButton,
                child: const Text(
                  'Cбросить',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Time {
  final int hour;
  final int min;
  final int sec;
  const Time({
    required this.hour,
    required this.min,
    required this.sec,
  });
}
