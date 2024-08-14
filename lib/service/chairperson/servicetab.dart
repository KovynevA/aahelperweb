import 'package:aahelper/helper/stylemenu.dart';
import 'package:aahelper/helper/utils.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:url_launcher/url_launcher.dart';

class CardsOfService extends StatefulWidget {
  const CardsOfService({super.key});

  @override
  State<CardsOfService> createState() => _CardsOfServiceState();
}

class _CardsOfServiceState extends State<CardsOfService> {
  List<ServiceCard> cards = [];
  Map<String, String> serviceName = {
    'Председатель': 'assets/images/director.jpg',
    'Секретарь': 'assets/images/secretary.jpg',
    'Казначей': 'assets/images/kazn1.jpg',
    'Чайханщик': 'assets/images/tea.jpeg',
    'Ведущий': 'assets/images/leading.png',
    'Спикерхантер': 'assets/images/speaker.jpg',
    'Библиотекарь': 'assets/images/biblio.jpg',
    'Телефон': 'assets/images/phone.jpg',
    'ПГО': 'assets/images/pgo.png',
  };
  ServiceUser? serviceUser;

  @override
  void initState() {
    super.initState();
    loadServiceuser();
    _loadCards();
  }

  void loadServiceuser() async {
    serviceUser = await getServiceUser();
  }

  Future<void> _loadCards() async {
    cards = await ServiceCard.loadServiceCards() ?? [];
    setState(() {});
  }

// Редактирование карточки
  void _showEditCardDialog(BuildContext context, int index) {
    var maskFormatter = MaskTextInputFormatter(
        mask: '+# (###) ###-##-##', filter: {"#": RegExp(r'[0-9]')});
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColor.backgroundColor,
          title: const Text(
            'Редактирование',
            style: AppTextStyle.menutextstyle,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Имя:', style: AppTextStyle.menutextstyle),
              Container(
                width: 200,
                height: 50,
                decoration: BoxDecoration(
                    border: Border.all(width: 1.5, color: Colors.brown),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.white24,
                        blurRadius: 2.0,
                        offset: Offset(2.0, 1.0),
                      )
                    ]),
                child: TextField(
                  style: AppTextStyle.valuesstyle,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: cards[index].name),
                  onChanged: (value) {
                    cards[index].name = value;
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text('Phone:', style: AppTextStyle.menutextstyle),
              TextField(
                style: AppTextStyle.valuesstyle,
                inputFormatters: [maskFormatter],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "+7 (___) _ _ _ - _ _ - _ _",
                ),
                controller: TextEditingController(text: cards[index].phone),
                onChanged: (value) {
                  cards[index].phone = value;
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                cards[index].id =
                    '${cards[index].serviceName}_${cards[index].name}';
                ServiceCard.updateServiceCard(cards[index]);
                Navigator.of(context).pop();
                setState(() {});
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      body: ListView.builder(
        itemCount: cards.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            // Вызов номера по двойному клику
            onDoubleTap: () {
              Uri phoneUrl = Uri(
                scheme: 'tel',
                path: cards[index].phone,
              );
              launchUrl(phoneUrl);
            },
            // Редактирование карточки по длинному нажатию
            onLongPress: () {
              _showEditCardDialog(context, index);
            },
            child: Dismissible(
              key: UniqueKey(),
              // Удаление карточки
              onDismissed: (direction) {
                setState(() {
                  cards.removeAt(index);
                  ServiceCard.deleteServiceCard(cards[index]);
                });
              },
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20.0),
                child: const Icon(Icons.delete),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.92,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColor.cardColor,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.all(10.0),
                        width: MediaQuery.of(context).size.width * 0.25,
                        height: MediaQuery.of(context).size.height * 0.25,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            fit: BoxFit.fill,
                            image: AssetImage(cards[index].avatar),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cards[index].serviceName,
                            style: AppTextStyle.menutextstyle,
                          ),
                          Text(
                            'Name: ${cards[index].name}\nPhone: ${cards[index].phone}',
                            style: AppTextStyle.valuesstyle,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: CustomFloatingActionButton(
        onPressed: () {
          if (isAutorization &&
              serviceUser!.type.contains(ServiceName.chairperson)) {
            _showAddCardModal(context);
          } else {
            infoSnackBar(context, 'Недостаточно прав');
          }
        },
        icon: Icons.add_box,
      ),
    );
  }

  void _showAddCardModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return AddCardPage(serviceName: serviceName);
      },
    ).then((newCard) {
      if (newCard != null) {
        cards.add(newCard);
        ServiceCard.saveServiceCards(cards);
        setState(() {});
      }
    });
  }
}

// Модальное окно добавления карточки
class AddCardPage extends StatefulWidget {
  final Map<String, String> serviceName;

  const AddCardPage({required this.serviceName, super.key});

  @override
  State<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  var maskFormatter = MaskTextInputFormatter(
      mask: '+# (###) ###-##-##', filter: {"#": RegExp(r'[0-9]')});
  late String selectedService;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedService = widget.serviceName.keys.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text('Имя:', style: AppTextStyle.menutextstyle),
                  Container(
                    width: 200,
                    height: 50,
                    decoration: BoxDecoration(
                        border: Border.all(width: 1.5, color: Colors.brown),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.white24,
                            blurRadius: 2.0,
                            offset: Offset(2.0, 1.0),
                          )
                        ]),
                    child: TextField(
                      style: AppTextStyle.valuesstyle,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      controller: _nameController,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 16,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text('Тел.:', style: AppTextStyle.menutextstyle),
                  Container(
                    width: 200,
                    height: 50,
                    decoration: BoxDecoration(
                        border: Border.all(width: 1.5, color: Colors.brown),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.white24,
                            blurRadius: 2.0,
                            offset: Offset(2.0, 1.0),
                          )
                        ]),
                    child: TextField(
                      style: AppTextStyle.valuesstyle,
                      inputFormatters: [maskFormatter],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "+7 (___) _ _ _ - _ _ - _ _",
                      ),
                      controller: _phoneController,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 16,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField(
                      style: AppTextStyle.menutextstyle,
                      value: selectedService,
                      items: widget.serviceName.keys.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: AppTextStyle.valuesstyle),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          selectedService = value!;
                        });
                      },
                    ),
                  ),
                  TextButton(
                    style: AppButtonStyle.iconButton,
                    onPressed: () {
                      Navigator.pop(
                        context,
                        ServiceCard(
                          id: '${selectedService}_${_nameController.text}',
                          serviceName: selectedService,
                          avatar: widget.serviceName[selectedService]!,
                          name: _nameController.text,
                          phone: _phoneController.text,
                        ),
                      );
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
