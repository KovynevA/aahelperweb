import 'package:aahelper/helper/stylemenu.dart';
import 'package:aahelper/helper/utils.dart';
import 'package:flutter/material.dart';

class MedalWidget extends StatefulWidget {
  const MedalWidget({super.key});

  @override
  State<MedalWidget> createState() => _MedalWidgetState();
}

class _MedalWidgetState extends State<MedalWidget> {
  List<Medal> medals = [];
  List<TextEditingController> quantityControllers = [];
  ServiceUser? serviceuser;

  @override
  void initState() {
    getServiceUser();
    Medal.loadMedalsFromFirestore().then((value) {
      setState(() {
        medals = value ?? [];
        quantityControllers = List.generate(
            medals.length,
            (index) =>
                TextEditingController(text: medals[index].quantity.toString()));
        if (medals.isEmpty) {
          medals.add(Medal('Новичку', 0));
          quantityControllers.add(TextEditingController(text: '0'));
        }
      });
    });
    super.initState();
  }

  void getServiceUser() async {
    if (isAutorization) {
      serviceuser =
          await ServiceUser.getServiceUserFromFirestore(currentUser!.email!);
    }
  }

  void addMedal() {
    setState(() {
      medals.add(Medal('Новичку', 0));
      quantityControllers.add(TextEditingController(text: '0'));
    });
  }

  void removeMedal() {
    setState(() {
      if (medals.isNotEmpty) {
        medals.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Text(
                'Книги в наличии:',
                style: AppTextStyle.menutextstyle,
              ),
              IconButton(onPressed: addMedal, icon: const Icon(Icons.add_box)),
              IconButton(
                onPressed: removeMedal,
                icon: const Icon(Icons.remove_circle),
              ),
            ],
          ),
          ListView.builder(
            shrinkWrap: true,
            itemCount: medals.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TreasureDropdownButton(
                      decoration: Decor.decorDropDownButton,
                      value: medals[index].title,
                      items: const [
                        'Новичку',
                        "1 месяц",
                        "3 месяца",
                        '6 месяцев',
                        '9 месяцев',
                        '1 год',
                        '2 года',
                        '3 года',
                        '4 года',
                        '5 лет',
                        '6 лет',
                        '7 лет',
                        '8 лет',
                        '9 лет',
                        '10 лет',
                      ],
                      onChanged: (String? value) {
                        setState(() {
                          medals[index].title = value!;
                        });
                      },
                      styleText: AppTextStyle.valuesstyle,
                    ),
                    TextFieldStyleWidget(
                      decoration: Decor.decorTextField,
                      sizeheight: 45,
                      sizewidth: MediaQuery.of(context).size.width * 0.30,
                      controller: quantityControllers[index],
                      onChanged: (value) {
                        setState(() {
                          medals[index].quantity = int.tryParse(value) ?? 0;
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          ElevatedButton(
            onPressed: () {
              Medal.saveMedalsToFirestore(medals);
              (serviceuser!.type.contains(ServiceName.chairperson) ||
                      serviceuser!.type.contains(ServiceName.leading))
                  ? infoSnackBar(context, 'Список сохранён')
                  : infoSnackBar(context, 'Недостаточно прав');
            },
            style: AppButtonStyle.dialogButton,
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}
