import 'package:aahelper/helper/stylemenu.dart';
import 'package:aahelper/helper/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  ServiceUser? serviceuser;
  bool isLoading = true;

  @override
  void initState() {
    loadServiceuser();
    super.initState();
  }

  void loadServiceuser() async {
    serviceuser = await getServiceUser();
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(), // Или другой виджет загрузки
      );
    } else {
      if (isAutorization &&
          serviceuser != null &&
          serviceuser!.type.contains(ServiceName.chairperson)) {
        return AdminpanelWidget(
          serviceUser: serviceuser!,
        );
      } else {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Меню доступно только для Председателя группы',
              style: AppTextStyle.menutextstyle,
            ),
          ),
        );
      }
    }
  }
}

class AdminpanelWidget extends StatefulWidget {
  final ServiceUser serviceUser;
  const AdminpanelWidget({super.key, required this.serviceUser});

  @override
  State<AdminpanelWidget> createState() => _AdminpanelWidgetState();
}

class _AdminpanelWidgetState extends State<AdminpanelWidget> {
  List<ServiceUser>? listUsers;
  ServiceUser? selectedUser;
  String? selectedEmailUser;
  List<ServiceName>? selectedTypeUser;

  @override
  void initState() {
    getListUsersFromDataBase();
    super.initState();
  }

  void getListUsersFromDataBase() async {
    final String nameGroup = widget.serviceUser.group;
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('service_users')
        .where('group', isEqualTo: nameGroup)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        listUsers = querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          List<ServiceName> userTypes = (data['type'] as List<dynamic>)
              .map((e) => ServiceName.values.firstWhere(
                  (enumValue) => enumValue.toString() == 'ServiceName.$e'))
              .toList();

          return ServiceUser(
            data['group'],
            data['name'],
            uid: data['uid'],
            email: data['email'],
            type: userTypes,
          );
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          Text(
            'Назначить служения:',
            style: AppTextStyle.menutextstyle,
          ),
          SizedBox(
            height: 10.0,
          ),
          Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
                height: 50,
                decoration: Decor.decorDropDownButton,
                child: DropdownButtonFormField<ServiceUser>(
                  dropdownColor: AppColor.cardColor,
                  hint: Text('Выбрать'),
                  style: AppTextStyle.valuesstyle,
                  value: selectedUser,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.only(left: 8.0),
                    border: UnderlineInputBorder(borderSide: BorderSide.none),
                    focusedBorder:
                        UnderlineInputBorder(borderSide: BorderSide.none),
                  ),
                  items: listUsers?.map((user) {
                    return DropdownMenuItem<ServiceUser>(
                      value: user,
                      child: Text(
                        user.email,
                        style: AppTextStyle.valuesstyle,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }).toList(),
                  onChanged: (ServiceUser? value) {
                    setState(() {
                      selectedEmailUser = value?.email;
                      selectedUser = value;
                      selectedTypeUser = value?.type;
                    });
                  },
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Wrap(
                spacing: 8.0,
                // игорируем admin, чтоб не попал в кнопки назначения прав
                children: ServiceName.values
                    .where((serviceName) => serviceName != ServiceName.admin)
                    .map((serviceName) {
                  return FilterChip(
                    label: Text(
                      getServiceNameTranslation(serviceName),
                      style: AppTextStyle.valuesstyle,
                    ),
                    selected: selectedTypeUser?.contains(serviceName) ?? false,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedTypeUser?.add(serviceName);
                        } else {
                          selectedTypeUser?.remove(serviceName);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: () {
                try {
                  ServiceUser.saveServiceUserToFirestore(selectedUser!);
                  infoSnackBar(context, 'Пользователь сохранён');
                } catch (e) {
                  infoSnackBar(context, 'Ошибка сохранения: $e');
                }
              },
              style: AppButtonStyle.dialogButton,
              child: const Text(
                'Назначить права',
              ),
            ),
          )
        ],
      ),
    );
  }
}
