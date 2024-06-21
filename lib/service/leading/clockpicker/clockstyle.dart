import 'package:flutter/material.dart';

class ClockContainer extends StatelessWidget {
  const ClockContainer({super.key, required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          color: Colors.black,
          border: Border.all(
            width: 2.0,
            color: Colors.white,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(5, 4),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              time,
              style: textClockStyle,
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle textClockStyle = const TextStyle(
    fontSize: 30,
    color: Colors.white,
    fontWeight: FontWeight.bold,
    shadows: [
      Shadow(
        color: Colors.deepPurple,
        offset: Offset(2, -1),
      ),
    ]);

Widget dotText = const Padding(
  padding: EdgeInsets.symmetric(horizontal: 5.0),
  child: Text(
    ':',
    style: TextStyle(
      color: Colors.white,
      fontSize: 30,
    ),
  ),
);

class LoopingListView extends StatefulWidget {
  const LoopingListView({
    super.key,
    required this.children,
    required this.onSelected,
    required this.scrollController,
    required this.isScrollEnabled,
  });

  final List<Widget> children;
  final void Function(int value) onSelected;
  final FixedExtentScrollController scrollController;
  final bool isScrollEnabled;

  @override
  State<LoopingListView> createState() => _LoopingListViewState();
}

class _LoopingListViewState extends State<LoopingListView> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      child: AbsorbPointer(
        absorbing: !widget.isScrollEnabled,
        child: ListWheelScrollView.useDelegate(
          controller: widget.scrollController,
          itemExtent: 60,
          perspective: 0.004,
          diameterRatio: 0.6,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (value) => widget.onSelected(value),
          childDelegate: ListWheelChildLoopingListDelegate(
            children: widget.children,
          ),
        ),
      ),
    );
  }
}
