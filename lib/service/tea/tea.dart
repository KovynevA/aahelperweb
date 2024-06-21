import 'package:aahelper/helper/stylemenu.dart';
import 'package:aahelper/helper/utils.dart';
import 'package:aahelper/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TeaMan extends StatelessWidget {
  const TeaMan({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        title: Text(title),
      ),
      body: const TeaWidget(),
    );
  }
}

//Общий виджет рабочка
class TeaWidget extends StatefulWidget {
  const TeaWidget({super.key});

  @override
  State<TeaWidget> createState() => _TeaWidgetState();
}

class _TeaWidgetState extends State<TeaWidget> {
  List<String> shop = [];
  List<String> complite = [];
  ServiceUser? serviceUser;

  @override
  void initState() {
    super.initState();
    loadServiceuser();
  }

  void loadServiceuser() async {
    serviceUser = await getServiceUser();
  }

  Future<void> _showInputDialog(
      BuildContext context, TeaProvider teaProvider) async {
    String text = ''; // Переменная для временного хранения введенного текста

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColor.backgroundColor,
          title: const Text(
            'Необходимо купить',
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
                teaProvider.changeshop([...teaProvider.shop, text]);
                shop.add(text);
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TeaProvider>(
      builder: (context, teaProvider, child) {
        shop = teaProvider.shop;
        complite = teaProvider.complete;

        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(6.0),
              child: Text(
                'Предстоящие покупки',
                style: AppTextStyle.menutextstyle,
              ),
            ),
            LimitedBox(
              maxHeight: MediaQuery.of(context).size.height * 0.3,
              child: TeaCards(
                shop: shop,
                complite: complite,
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(6.0),
              child: Text(
                'Завершённые покупки',
                style: AppTextStyle.menutextstyle,
              ),
            ),
            LimitedBox(
              maxHeight: MediaQuery.of(context).size.height * 0.3,
              child: CompliteTeaCards(
                complite: complite,
                shop: shop,
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: CustomFloatingActionButton(
                  onPressed: () {
                    if (isAutorization &&
                        (serviceUser!.type.contains(ServiceName.chairperson) ||
                            serviceUser!.type.contains(ServiceName.tea))) {
                      _showInputDialog(context, teaProvider);
                    } else {
                      infoSnackBar(context, 'Недостаточно прав');
                    }
                  },
                  icon: Icons.add_box,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

//Карточки с вопросами на рабочку
class TeaCards extends StatefulWidget {
  final List<String> shop;
  final List<String> complite;
  const TeaCards({super.key, required this.shop, required this.complite});

  @override
  State<TeaCards> createState() => _TeaCardsState();
}

class _TeaCardsState extends State<TeaCards> {
  final bool _checkvalue = false;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemExtent: 60,
      itemCount: widget.shop.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Dismissible(
            key: Key(widget.shop[index]),
            //key: UniqueKey(),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              child: const Icon(Icons.delete, color: Colors.black),
            ),
            onDismissed: (direction) {
              setState(() {
                widget.shop.removeAt(index);
                Provider.of<TeaProvider>(context, listen: false)
                    .changeshop(widget.shop);
              });
            },
            child: Material(
              child: CheckboxListTile(
                tileColor: AppColor.cardColor,
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Text(
                    widget.shop[index],
                    style: AppTextStyle.valuesstyle,
                  ),
                ),
                value: _checkvalue,
                onChanged: (value) {
                  setState(() {
                    widget.complite.add(widget.shop[index]);
                    widget.shop.removeAt(index);
                    Provider.of<TeaProvider>(context, listen: false)
                        .changeshop(widget.shop);
                    Provider.of<TeaProvider>(context, listen: false)
                        .changecomplite(widget.complite);
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
class CompliteTeaCards extends StatefulWidget {
  final List<String> shop;
  final List<String> complite;
  const CompliteTeaCards(
      {super.key, required this.complite, required this.shop});

  @override
  State<CompliteTeaCards> createState() => _CompliteTeaCardsState();
}

class _CompliteTeaCardsState extends State<CompliteTeaCards> {
  final bool _checkvalue = true;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemExtent: 60,
      itemCount: widget.complite.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Dismissible(
            key: Key(widget.complite[index]),
            //key: UniqueKey(),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              child: const Icon(Icons.delete, color: Colors.black),
            ),
            onDismissed: (direction) {
              setState(() {
                widget.complite.removeAt(index);
                Provider.of<TeaProvider>(context, listen: false)
                    .changeshop(widget.shop);
                Provider.of<TeaProvider>(context, listen: false)
                    .changecomplite(widget.complite);
              });
            },
            child: Material(
              child: CheckboxListTile(
                tileColor: AppColor.deleteCardColor,
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Text(
                    widget.complite[index],
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
                    widget.shop.add(widget.complite[index]);
                    widget.complite.removeAt(index);
                    Provider.of<TeaProvider>(context, listen: false)
                        .changeshop(widget.shop);
                    Provider.of<TeaProvider>(context, listen: false)
                        .changecomplite(widget.complite);
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
