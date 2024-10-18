import 'package:aahelper/helper/firebase_config.dart';
import 'package:aahelper/helper/utils.dart';
import 'package:aahelper/homapage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

// Модель провайдера
class ServiceProvider extends ChangeNotifier {
  List<String> questions = [];
  List<String> completedquetions = [];
  ProfitGroup? totalProfit;
  String speakerData = '';
  bool _updateData = false;

  bool get updateData => _updateData;

  void updateState(bool trueData) {
    _updateData = trueData;
    notifyListeners();
  }

  Future<void> loadData() async {
    if (isAutorization) {
      ServiceUser? serviceUser = await getServiceUser();
      final String nameGroupCollection = serviceUser!.group;
      try {
        DocumentSnapshot? questionsDoc = await FirebaseFirestore.instance
            .collection('allgroups')
            .doc(nameGroupCollection)
            .collection('questions')
            .doc('questions')
            .get();
        questions = (questionsDoc.data() as Map<String, dynamic>)['question']
                .cast<String>() ??
            [];

        DocumentSnapshot? completedQuestionsDoc = await FirebaseFirestore
            .instance
            .collection('allgroups')
            .doc(nameGroupCollection)
            .collection('completedQuestions')
            .doc('completedQuestions')
            .get();
        completedquetions = (completedQuestionsDoc.data()
                    as Map<String, dynamic>)['completedQuestion']
                .cast<String>() ??
            [];

        notifyListeners();
      } catch (e) {
        // Обработка ошибок при чтении данных
        debugPrint('Ошибка при загрузке вопросов на рабочку: $e');
        questions = [];
        completedquetions = [];
      }
    }
  }

  Future<void> saveData() async {
    ServiceUser? serviceUser = await getServiceUser();
    final String nameGroupCollection = serviceUser!.group;
    if (serviceUser.type.contains(ServiceName.chairperson)) {
      try {
        await FirebaseFirestore.instance
            .collection('allgroups')
            .doc(nameGroupCollection)
            .collection('questions')
            .doc('questions')
            .set({'question': questions});
        await FirebaseFirestore.instance
            .collection('allgroups')
            .doc(nameGroupCollection)
            .collection('completedQuestions')
            .doc('completedQuestions')
            .set({'completedQuestion': completedquetions});

        notifyListeners();
      } catch (e) {
        // Обработка ошибок при сохранении данных
        debugPrint('Ошибка при сохранении данных: $e');
      }
    }
  }

  ServiceProvider() {
    Future.delayed(Duration.zero, () {
      loadData();
    });
  }
// обновить вопросы
  void changequestions(List<String> newquestions) {
    questions = newquestions;
    saveData();
    notifyListeners();
  }

// завершенные вопросы на рабочку
  void changecomplitedquetions(List<String> newcomplitedquetions) {
    completedquetions = newcomplitedquetions;
    saveData();
    notifyListeners();
  }

  void updateDates(ProfitGroup? newtotalProfit) {
    totalProfit = newtotalProfit;
    notifyListeners();
  }

  // Метод для обновления данных о спикере
  void updateSpeakerData(String newData) {
    speakerData = newData;
    notifyListeners();
  }
}

// Модель провайдера
class TeaProvider extends ChangeNotifier {
  List<String> shop = [];
  List<String> complete = [];

  Future<void> loadTeaData() async {
    if (isAutorization) {
      ServiceUser? serviceUser = await getServiceUser();
      final String nameGroupCollection = serviceUser!.group;
      try {
        DocumentSnapshot? shopDoc = await FirebaseFirestore.instance
            .collection('allgroups')
            .doc(nameGroupCollection)
            .collection('shop')
            .doc('shop')
            .get();
        shop =
            (shopDoc.data() as Map<String, dynamic>)['item'].cast<String>() ??
                [];

        DocumentSnapshot? completeDoc = await FirebaseFirestore.instance
            .collection('allgroups')
            .doc(nameGroupCollection)
            .collection('complete')
            .doc('complete')
            .get();
        complete = (completeDoc.data() as Map<String, dynamic>)['completeItem']
                .cast<String>() ??
            [];

        notifyListeners();
      } catch (e) {
        // Обработка ошибок при чтении данных
        debugPrint('Ошибка при загрузке чайханщика: $e');
        shop = [];
        complete = [];
      }
    }
  }

  Future<void> saveTeaData() async {
    ServiceUser? serviceUser = await getServiceUser();
    final String nameGroupCollection = serviceUser!.group;
    if (serviceUser.type.contains(ServiceName.chairperson) ||
        serviceUser.type.contains(ServiceName.tea)) {
      try {
        await FirebaseFirestore.instance
            .collection('allgroups')
            .doc(nameGroupCollection)
            .collection('shop')
            .doc('shop')
            .set({'item': shop});
        await FirebaseFirestore.instance
            .collection('allgroups')
            .doc(nameGroupCollection)
            .collection('complete')
            .doc('complete')
            .set({'completeItem': complete});

        notifyListeners();
      } catch (e) {
        // Обработка ошибок при сохранении данных
        debugPrint('Ошибка при сохранении данных: $e');
      }
    }
  }

  TeaProvider() {
    Future.delayed(Duration.zero, () {
      loadTeaData();
    });
  }
// обновить вопросы
  void changeshop(List<String> newshop) {
    shop = newshop;
    saveTeaData();
    notifyListeners();
  }

// завершенные вопросы на рабочку
  void changecomplite(List<String> newcomplite) {
    complete = newcomplite;
    saveTeaData();
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: FirebaseOptions(
    apiKey: FirebaseConfig.apiKey,
    appId: FirebaseConfig.appId,
    messagingSenderId: FirebaseConfig.messagingSenderId,
    projectId: FirebaseConfig.projectId,
  ));

  initializeDateFormatting('ru_RU', null).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ServiceProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => TeaProvider(),
        )
      ],
      child: const MaterialApp(
        home: MyHomePage(),
      ),
    );
  }
}
