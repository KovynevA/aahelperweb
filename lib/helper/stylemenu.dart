import 'package:flutter/material.dart';

// Стиль полей ввода
class TextFieldStyleWidget extends StatelessWidget {
  final void Function(String)? onChanged;
  final TextEditingController? controller;
  final double sizewidth;
  final double sizeheight;
  final Decoration? decoration;
  const TextFieldStyleWidget({
    super.key,
    this.onChanged,
    this.controller,
    this.sizeheight = 50,
    this.sizewidth = 105,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: sizewidth,
      height: sizeheight,
      decoration: decoration ??
          BoxDecoration(
              border: Border.all(width: 1.5, color: Colors.brown),
              boxShadow: const [
                BoxShadow(
                  color: Colors.white24,
                  blurRadius: 2.0,
                  offset: Offset(2.0, 1.0),
                )
              ]),
      child: TextFormField(
        textAlignVertical: TextAlignVertical.center,
        controller: controller,
        maxLines: null,
        expands: true,
        onChanged: onChanged,
        style: AppTextStyle.valuesstyle,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
        ),
      ),
    );
  }
}

// Виджет ТЕКСТ + Поле ввода текста
class AnimatedTextAndTextFieldWidget extends StatefulWidget {
  final String text;
  final TextEditingController controller;

  const AnimatedTextAndTextFieldWidget({
    super.key,
    required this.text,
    required this.controller,
  });

  @override
  State<AnimatedTextAndTextFieldWidget> createState() =>
      _AnimatedTextAndTextFieldWidgetState();
}

class _AnimatedTextAndTextFieldWidgetState
    extends State<AnimatedTextAndTextFieldWidget> {
  bool _isTextFieldFocused = false;

  void _handleTextFieldFocusChange(bool hasFocus) {
    setState(() {
      _isTextFieldFocused = hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: AnimatedContainer(
        height: _isTextFieldFocused
            ? MediaQuery.of(context).size.height * 0.1
            : MediaQuery.of(context).size.height * 0.05,
        duration: const Duration(milliseconds: 200),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.text,
                style: AppTextStyle.menutextstyle,
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: _isTextFieldFocused
                    ? Alignment.center
                    : Alignment.centerRight,
                child: AnimatedTextFieldStyleWidget(
                  decoration: Decor.decorTextField,
                  sizeheight: MediaQuery.of(context).size.height * 0.5,
                  sizewidth: MediaQuery.of(context).size.width * 0.30,
                  controller: widget.controller,
                  //onChanged: widget.onChanged,
                  onFocusChanged: _handleTextFieldFocusChange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Виджет стиля поля ввода текста
class AnimatedTextFieldStyleWidget extends StatefulWidget {
  final void Function(String)? onChanged;
  final void Function(bool)? onFocusChanged;
  final TextEditingController? controller;
  final double? sizewidth;
  final double? sizeheight;
  final Decoration? decoration;

  const AnimatedTextFieldStyleWidget({
    super.key,
    this.onChanged,
    this.onFocusChanged,
    this.controller,
    this.sizeheight,
    this.sizewidth,
    this.decoration,
  });

  @override
  State<AnimatedTextFieldStyleWidget> createState() =>
      _AnimatedTextFieldStyleWidgetState();
}

class _AnimatedTextFieldStyleWidgetState
    extends State<AnimatedTextFieldStyleWidget> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      width: _isFocused
          ? MediaQuery.of(context).size.width * 0.9
          : widget.sizewidth,
      height: _isFocused
          ? MediaQuery.of(context).size.height * 0.1
          : widget.sizeheight,
      duration: const Duration(milliseconds: 200),
      decoration: widget.decoration ??
          BoxDecoration(
            border: Border.all(width: 1.5, color: Colors.brown),
            boxShadow: const [
              BoxShadow(
                color: Colors.white24,
                blurRadius: 2.0,
                offset: Offset(2.0, 1.0),
              )
            ],
          ),
      child: Focus(
        onFocusChange: (hasFocus) {
          setState(() {
            _isFocused = hasFocus;
          });
          if (widget.onFocusChanged != null) {
            widget.onFocusChanged!(hasFocus);
          }
        },
        child: TextFormField(
          textAlignVertical: TextAlignVertical.center,
          controller: widget.controller,
          maxLines: null,
          expands: true,
          onChanged: widget.onChanged,
          style: AppTextStyle.valuesstyle,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 6.0),
          ),
        ),
      ),
    );
  }
}

// Меню выбора DropDownButton
class TreasureDropdownButton extends StatelessWidget {
  final String value;
  final List<String> items;
  final Function(String?) onChanged;
  final TextStyle styleText;
  final Decoration? decoration;

  const TreasureDropdownButton({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.styleText,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: decoration ?? const BoxDecoration(),
      child: DropdownButton<String>(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        value: value,
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: styleText,
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

//Стиль карточек текст и поле ввода
class TextAndTextFieldWidget extends StatelessWidget {
  final String text;
  final TextEditingController controller;
  const TextAndTextFieldWidget(
      {super.key, required this.text, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              text,
              style: AppTextStyle.menutextstyle,
            ),
          ),
          Expanded(
            child: TextFieldStyleWidget(
              decoration: Decor.decorTextField,
              sizeheight: MediaQuery.of(context).size.height * 0.05,
              sizewidth: double.infinity,
              controller: controller,
            ),
          ),
        ],
      ),
    );
  }
}

// плавающие кнопки
class CustomFloatingActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const CustomFloatingActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: UniqueKey(),
      onPressed: onPressed,
      child: Icon(icon),
    );
  }
}

// Стиль кнопок
abstract class AppButtonStyle {
  static final ButtonStyle iconButton = ButtonStyle(
    backgroundColor:
        WidgetStateProperty.all(const Color.fromARGB(185, 120, 155, 131)),
    shadowColor: WidgetStateProperty.all(Colors.grey),
    elevation: WidgetStateProperty.all(10.0),
    // fixedSize: MaterialStateProperty.all(const Size(75, 25)),
    side: WidgetStateProperty.all(
      const BorderSide(width: 2.0, color: Colors.brown),
    ),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
    ),
  );

  static final ButtonStyle dialogButton = ButtonStyle(
    backgroundColor: WidgetStateProperty.all(Colors.white54),
    shadowColor: WidgetStateProperty.all(Colors.grey),
    elevation: WidgetStateProperty.all(10.0),
    //fixedSize: MaterialStateProperty.all(const Size(140, 30)),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
    ),
  );
}

abstract class AppTextStyle {
  static const menutextstyle = TextStyle(
    color: Colors.black,
    fontWeight: FontWeight.bold,
    fontSize: 18,
    shadows: [
      Shadow(
        color: Colors.blueGrey,
        blurRadius: 2.0,
        offset: Offset(1.0, 0.0),
      )
    ],
  );

  static const valuesstyle = TextStyle(
    color: Colors.black,
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  static const minimalsstyle = TextStyle(
    color: Colors.brown,
    fontWeight: FontWeight.bold,
    //fontStyle: FontStyle.italic,
    fontSize: 12,
  );

  static const spantextstyle = TextStyle(
    color: Colors.brown,
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.italic,
    fontSize: 14,
  );
}

abstract class AppColor {
  static const defaultColor = Color.fromARGB(255, 225, 218, 245);
  static const backgroundColor = Color.fromRGBO(223, 234, 232, 1);
  static const cardColor = Color.fromRGBO(235, 218, 199, 1);
  static const deleteCardColor = Color.fromARGB(255, 191, 161, 227);
}

abstract class Decor {
  static const decorDropDownButton = BoxDecoration(
    gradient: LinearGradient(colors: [
      AppColor.deleteCardColor,
      AppColor.backgroundColor,
    ]),
    boxShadow: <BoxShadow>[
      BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.57), //shadow for button
          blurRadius: 0) //blur radius of shadow
    ],
  );

  static final decorTextField = BoxDecoration(
    border: Border.all(width: 1.5, color: AppColor.deleteCardColor),
    gradient: const LinearGradient(colors: [
      AppColor.cardColor,
      AppColor.backgroundColor,
    ]),
    boxShadow: const <BoxShadow>[
      BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.57), //shadow for button
          blurRadius: 5) //blur radius of shadow
    ],
  );
}
