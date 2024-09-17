import 'package:aahelper/helper/stylemenu.dart';
import 'package:aahelper/helper/utils.dart';
import 'package:aahelper/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthentificationWidget extends StatefulWidget {
  final VoidCallback updateCallbackSettingPage;
  const AuthentificationWidget(
      {super.key, required this.updateCallbackSettingPage});

  @override
  State<AuthentificationWidget> createState() => _AuthentificationWidgetState();
}

class _AuthentificationWidgetState extends State<AuthentificationWidget> {
  final TextEditingController logincontroller = TextEditingController();
  final TextEditingController passwordcontroller = TextEditingController();
  TextEditingController nameleading = TextEditingController();
  String? selectedNameGroup;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  ServiceUser? serviceuser;
  String admingroup = 'Вешняки';
  TextEditingController adminGroupController = TextEditingController();
  List<String> groups = [];
  StateSetter? dialogStateSetter;

  @override
  void initState() {
    isAutorization
        ? {
            loadServiceUser(),
          }
        : {
            fetchGroups().then((onValue) {
              setState(() {
                selectedNameGroup = 'Выберите группу';
                nameleading.text = '';
              });
            })
          };
    super.initState();
  }

  void loadServiceUser() async {
    ServiceUser? user = await getServiceUser();
    if (user != null) {
      setState(() {
        serviceuser = user;
        selectedNameGroup = serviceuser?.group;
        nameleading.text = serviceuser!.name;
      });
    }
  }

  // callback
  void onCallbackSettingPage() {
    setState(() {
      widget.updateCallbackSettingPage();
    }); // Вызов колбэка для обновления календаря в MyHomePage
  }

  void onCreateUserFromFireStore() {
    if (serviceuser == null) {
      ServiceUser? serviceUser = ServiceUser(
        selectedNameGroup!,
        nameleading.text,
        uid: currentUser!.uid,
        email: currentUser!.email!,
        type: [ServiceName.user],
      );
      ServiceUser.saveServiceUserToFirestore(serviceUser);
      onCallbackSettingPage();
      if (currentUser != null) {
        infoSnackBar(context, 'Регистрация успешна');
      } else {
        infoSnackBar(context, 'Регистрация НЕ успешна');
      }
      loadServiceUser();
      setState(() {});
    } else {
      selectedNameGroup = serviceuser?.group;
      nameleading.text = serviceuser?.name ?? '';
      infoSnackBar(context, 'Пользователь существует');
    }
  }

// Создать нового пользователя в базе (регистрация)
  void createUser() async {
    if (logincontroller.text.isNotEmpty &&
        passwordcontroller.text.isNotEmpty &&
        nameleading.text.isNotEmpty &&
        selectedNameGroup != 'Выберете группу') {
      try {
        await _auth.createUserWithEmailAndPassword(
          email: logincontroller.text,
          password: passwordcontroller.text,
        );
        isAutorization = true;
        currentUser = FirebaseAuth.instance.currentUser;
        onCreateUserFromFireStore();
        setState(() {});
      } catch (e) {
        String errorMessage = '';
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'weak-password':
              errorMessage =
                  'Слабый пароль. Пароль должен содержать не менее 6 символов.';
              break;
            case 'email-already-in-use':
              errorMessage = 'Пользователь с таким email уже зарегистрирован.';
              break;
            // Другие возможные причины ошибок
            default:
              errorMessage = 'Произошла ошибка при регистрации пользователя.';
          }
        }
        // Обработка ошибок при регистрации
        if (mounted) {
          infoSnackBar(context, errorMessage);
        }
      }
    } else {
      infoSnackBar(context, 'Необходимо заполнить все поля');
    }
  }

  Future<void> fetchGroups() async {
    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('allgroups').get();

      if (snapshot.docs.isNotEmpty) {
        List<String> loadedGroups = snapshot.docs.map((doc) => doc.id).toList();

        groups = loadedGroups;
      } else {
        print('No groups found in Firestore');
      }
    } catch (e) {
      print('Error fetching groups: $e');
    }
  }

  // Диалоговое окно выбора или добавления группы для админа
  void showDialogSelectedGroupForAdmin() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          dialogStateSetter = setState;
          return AlertDialog(
            backgroundColor: AppColor.backgroundColor,
            title: Text(
              'Меню выбора групп Администратором',
              style: AppTextStyle.valuesstyle,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  alignment: WrapAlignment.spaceAround,
                  children: [
                    Text(
                      'Выберете \n группу',
                      style: AppTextStyle.menutextstyle,
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 2),
                      decoration: Decor.decorDropDownButton,
                      child: DropdownButton<String>(
                        value: admingroup,
                        items: groups.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: AppTextStyle.valuesstyle,
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newvalue) {
                          setState(() {
                            admingroup = newvalue!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 15,
                ),
                Center(
                  child: TextButton(
                    style: AppButtonStyle.dialogButton,
                    onPressed: () {
                      // Perform action with selectedGroup
                      ServiceUser? user = ServiceUser(admingroup, 'Андрей',
                          uid: currentUser!.uid,
                          email: currentUser!.email!,
                          type: [ServiceName.admin, ServiceName.chairperson]);
                      serviceuser = user;
                      selectedNameGroup = serviceuser?.group;
                      nameleading.text = serviceuser!.name;
                      ServiceUser.saveServiceUserToFirestore(serviceuser!);
                      loadQuestionsForWorkMeeting();
                      onCallbackSettingPage();
                      Navigator.of(context).pop();
                    },
                    child: Text('Выбрать группу'),
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                TextAndTextFieldWidget(
                    sizewidth: MediaQuery.of(context).size.width * 0.28,
                    text: 'Новая группа',
                    controller: adminGroupController),
              ],
            ),
            actions: <Widget>[
              Center(
                child: TextButton(
                  style: AppButtonStyle.dialogButton,
                  onPressed: () {
                    setState(() {
                      addNewGroup();
                      onCallbackSettingPage();
                    });
                  },
                  child: Text('Добавить группу'),
                ),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> addNewGroup() async {
    await FirebaseFirestore.instance
        .collection('allgroups')
        .doc(adminGroupController.text)
        .set({});

    groups.add(adminGroupController.text);
    adminGroupController.clear();
    dialogStateSetter!(() {}); // Вызываем StateSetter для обновления виджета
  }

// Авторизация зарегистрированного пользователя
  void signIn() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: logincontroller.text,
        password: passwordcontroller.text,
      );
      isAutorization = true;
      currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        if (currentUser?.email == 'kovinas@bk.ru') {
          // await fetchGroups();

          showDialogSelectedGroupForAdmin();
        } else {
          loadServiceUser();
          infoSnackBar(context, 'Вход выполнен');

          onCallbackSettingPage();
        }
      }
      loadQuestionsForWorkMeeting();
    } 
    on FirebaseAuthException catch (e) {
    // Обработка ошибок при входе
    if (e.code == 'network-request-failed') {
      infoSnackBar(context, 'Ошибка сети: проверьте подключение и повторите попытку');
    } else {
      infoSnackBar(context, 'Ошибка при входе: ${e.message}');
    }
  }
    catch (e) {
      // Обработка ошибок при входе
      debugPrint(e.toString());
      if (mounted) {
        infoSnackBar(context, 'Вход не выполнен, ${e.toString}');
      }
    }
  }

  void loadQuestionsForWorkMeeting() async {
    Provider.of<ServiceProvider>(context, listen: false).loadData();
  }

  void signOutUser() async {
    try {
      await _auth.signOut();
      await fetchGroups();
      setState(() {
        currentUser = null;
        serviceuser = null;
        isAutorization = false;
        infoSnackBar(context, 'Вы вышли из аккаунта');
        onCallbackSettingPage();
      });
    } catch (e) {
      debugPrint('Ошибка выхода пользователя${e.toString()}');
      infoSnackBar(context, 'Ошибка выхода пользователя${e.toString()}');
    }
  }

  void resetPassword(TextEditingController? emailController) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Сброс забытого пароля',
            style: AppTextStyle.menutextstyle,
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  'Введите email',
                  style: AppTextStyle.valuesstyle,
                ),
                TextField(
                  controller: emailController ?? TextEditingController(),
                ),
                Text(
                  'Нажав на кнопку "Изменить", на Вашу почту придет письмо, в котором будет ссылка на изменение пароля. Старый пароль больше действовать не будет!',
                  softWrap: true,
                  style: AppTextStyle.minimalsstyle,
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (emailController?.text != '') {
                      await _auth.sendPasswordResetEmail(
                          email: emailController!.text);
                      Navigator.of(context).pop();
                    } else {
                      infoSnackBar(context, 'Введите свой email');
                    }
                  },
                  child: Text('Сбросить пароль'),
                  style: AppButtonStyle.dialogButton,
                ),
                ElevatedButton(
                  onPressed: Navigator.of(context).pop,
                  child: Text('Отмена'),
                  style: AppButtonStyle.dialogButton,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    logincontroller.dispose();
    passwordcontroller.dispose();
    nameleading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return (currentUser != null)
        ? Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Center(
                  child: Text(
                    'Группа ${serviceuser?.group}',
                    style: AppTextStyle.menutextstyle,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    'Добро пожаловать, ${serviceuser?.name}',
                    style: AppTextStyle.valuesstyle,
                  ),
                  ElevatedButton(
                    style: AppButtonStyle.dialogButton,
                    onPressed: () {
                      signOutUser();
                    },
                    child: const Text('Выйти'),
                  ),
                ],
              ),
            ],
          )
        : Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Column(
                    children: [
                      Text(
                        'Почта:',
                        style: AppTextStyle.menutextstyle,
                      ),
                      SizedBox(
                        height: 20.0,
                      ),
                      Text(
                        'Пароль:',
                        style: AppTextStyle.menutextstyle,
                      ),
                      SizedBox(
                        height: 20.0,
                      ),
                      Text(
                        'Ваше имя:',
                        style: AppTextStyle.menutextstyle,
                      ),
                      SizedBox(
                        height: 20.0,
                      ),
                      Text(
                        'Группа АА:',
                        style: AppTextStyle.menutextstyle,
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(
                        height: 5.0,
                      ),
                      TextFieldStyleWidget(
                        decoration: Decor.decorTextField,
                        sizewidth: MediaQuery.of(context).size.width / 2,
                        sizeheight: 40,
                        controller: logincontroller,
                        //  onChanged: (p0) => {},
                      ),
                      const SizedBox(
                        height: 5.0,
                      ),
                      TextFieldStyleWidget(
                        decoration: Decor.decorTextField,
                        sizewidth: MediaQuery.of(context).size.width / 2,
                        sizeheight: 40,
                        controller: passwordcontroller,
                      ),
                      const SizedBox(
                        height: 5.0,
                      ),
                      TextFieldStyleWidget(
                        decoration: Decor.decorTextField,
                        sizewidth: MediaQuery.of(context).size.width / 2,
                        sizeheight: 40,
                        controller: nameleading,
                        // onChanged: (p0) => {},
                      ),
                      const SizedBox(
                        height: 5.0,
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 2),
                        width: MediaQuery.of(context).size.width / 1.8,
                        height: 50,
                        decoration: Decor.decorDropDownButton,
                        child: DropdownButtonFormField(
                          hint: Text('Выберите группу'),
                          style: AppTextStyle.valuesstyle,
                          value: selectedNameGroup,
                          items: groups.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: AppTextStyle.valuesstyle,
                                textAlign: TextAlign.center,
                              ),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            setState(() {
                              selectedNameGroup = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 18.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(
                      onPressed: () {
                        createUser();
                        setState(() {});
                      },
                      style: AppButtonStyle.dialogButton,
                      child: const Text('Зарегистрироваться'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          signIn();
                        });
                      },
                      style: AppButtonStyle.dialogButton,
                      child: const Text('Войти'),
                    ),
                  ],
                ),
              ),
              Center(
                  child: TextButton(
                onPressed: () => resetPassword(logincontroller),
                child: Text('Сбросить пароль'),
              )),
            ],
          );
  }
}
