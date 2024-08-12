import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

final kEvents = LinkedHashMap<DateTime, List<Event>>(
  equals: isSameDay,
  hashCode: getHashCode,
);

int getHashCode(DateTime key) {
  return key.day * 1000000 + key.month * 10000 + key.year;
}

User? currentUser = FirebaseAuth.instance.currentUser;
bool isAutorization = currentUser == null ? false : true;
final kToday = DateTime.now();
final kFirstDay = DateTime(kToday.year, kToday.month - 6, kToday.day);
final kLastDay = DateTime(kToday.year, kToday.month + 3, kToday.day);

Future<ServiceUser?> getServiceUser() async {
  if (isAutorization) {
    return await ServiceUser.getServiceUserFromFirestore(currentUser!.email!);
  } else {
    return null;
  }
}

// Сравнение дат без времени
bool compareDate(DateTime date1, DateTime date2) {
  if (date1.day == date2.day &&
      date1.month == date2.month &&
      date1.year == date2.year) {
    return true;
  } else {
    return false;
  }
}

List<String> daysOfWeek = [
  'Пн',
  'Вт',
  'Ср',
  'Чт',
  'Пт',
  'Сб',
  'Вс',
];
// SnackBar внизу экрана
void infoSnackBar(BuildContext context, String text) {
  final snackBar = SnackBar(
    content: Text(text),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

///////// ************СОБЫТИЯ*************////////////////
class Event {
  final String title;
  final RepeatOptions repeatOption;
  const Event(this.title, this.repeatOption);
  @override
  String toString() => title;

  // Удалить  события "рабочее собрание"
  static void removeOldWorkMeetingsSchedule() async {
    DateTime currentDate = kFirstDay;
    while (currentDate.isBefore(kLastDay)) {
      if (kEvents[currentDate] != null) {
        kEvents[currentDate]
            ?.removeWhere((event) => event.title == 'Рабочее собрание');
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }
    saveEventsToFirestore();
  }

// Номер дня недели
  static int getWeekdayIndex(String day) {
    return daysOfWeek.indexOf(day) + 1;
  }

// Удалить событие "Собрание группы" для одного дня (снимаем галку)
  static void removeMeetingEvents(String day) async {
    kEvents.forEach((key, value) {
      value.removeWhere((event) =>
          event.title == 'Собрание группы' &&
          key.weekday == getWeekdayIndex(day));
    });
    saveEventsToFirestore();
  }

// Удалить событие "Спикерская" для одного дня (снимаем галку)
  static void removeSpeakerEvent(DateTime date) {
    kEvents[date]?.removeWhere((event) => event.title.startsWith('Спикерская'));
    saveEventsToFirestore();
  }

// Преобразование объекта Event в Map
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'repeatOption': repeatOption.toJson(),
    };
  }

  // Создание объекта Event из Map
  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      map['title'],
      RepeatOptions.fromMap(map['repeatOption']),
    );
  }

  // Загрузить календарь событий из Firestore
  static Future<void> loadEventsFromFirestore(
      RepeatOptions repeatOption) async {
    // Заполняем, если авторизован
    if (isAutorization) {
      ServiceUser? serviceUser = await getServiceUser();
      final String nameGroupCollection = serviceUser!.group;
      try {
        DocumentSnapshot<Map<String, dynamic>> snapshot =
            await FirebaseFirestore.instance
                .collection(nameGroupCollection)
                .doc('namegroup_id')
                .collection('events')
                .doc('eventsData')
                .get();

        kEvents.clear();

        Map<String, dynamic>? data = snapshot.data();

        if (data != null) {
          data.forEach((key, value) {
            DateTime date =
                DateTime.fromMillisecondsSinceEpoch(int.tryParse(key) ?? 0);
            List<Event> events = (value as List<dynamic>)
                .map((e) => Event.fromMap(e as Map<String, dynamic>))
                .toList();
            kEvents[date] = events;
          });
        }
      } catch (e) {
        // Обработка ошибок при загрузке
        debugPrint('Ошибка при загрузке событий из Firestore: $e');
      }
    } else {
      kEvents.clear();
    }
  }

// Сохранить календарь событий в Firestore
  static void saveEventsToFirestore() async {
    ServiceUser? serviceUser = await getServiceUser();
    final String nameGroupCollection = serviceUser!.group;
    if (serviceUser.type.contains(ServiceName.chairperson)) {
      try {
        // очищаем прошлые события из базы
        await FirebaseFirestore.instance
            .collection(nameGroupCollection)
            .doc('namegroup_id')
            .collection('events')
            .doc('eventsData')
            .delete();

        Map<String, dynamic> eventsMap = {};
        kEvents.forEach((key, value) {
          eventsMap[key.millisecondsSinceEpoch.toString()] =
              value.map((e) => e.toJson()).toList();
        });

        await FirebaseFirestore.instance
            .collection(nameGroupCollection)
            .doc('namegroup_id')
            .collection('events')
            .doc('eventsData')
            .set(eventsMap);
      } catch (e) {
        // Обработка ошибок при сохранении
        debugPrint('Ошибка при сохранении событий в Firestore: $e');
      }
    }
  }
}

//Класс повторов
class RepeatOptions {
  final String label;
  final RepeatType type;

  RepeatOptions(this.label, this.type);
// переопределение операции сравнения
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RepeatOptions && other.label == label && other.type == type;
  }

  @override
  int get hashCode {
    return label.hashCode ^ type.hashCode;
  }

  // Преобразование объекта RepeatOptions в Map
  Map<String, dynamic> toJson() => {
        'label': label,
        'type': type.toString(),
      };

  // Создание объекта RepeatOptions из Map
  factory RepeatOptions.fromMap(Map<String, dynamic> map) {
    return RepeatOptions(
      map['label'],
      RepeatType.values.firstWhere((e) => e.toString() == map['type']),
    );
  }
}

//Возможные повторы в календаре
enum RepeatType {
  weekly,
  monthly,
  year,
  other,
  none,
}

///////// ************Класс Доход группы*************////////////////
class ProfitGroup {
  DateTime date;
  double? sevenTraditioncash;
  double? sevenTraditioncard;
  double? profitliteratura;
  double? profitother;

  double? expensiveliteratura;
  double? tea;
  double? medal;
  double? postmail;
  double? expensiveother;

  ProfitGroup({
    required this.date,
    this.sevenTraditioncash,
    this.sevenTraditioncard,
    this.profitliteratura,
    this.profitother,
    this.expensiveliteratura,
    this.tea,
    this.medal,
    this.postmail,
    this.expensiveother,
  });

  // Преобразование объекта ProfitGroup в Map
  Map<String, dynamic> toJson() => {
        'date': date,
        'sevenTraditioncash': sevenTraditioncash,
        'sevenTraditioncard': sevenTraditioncard,
        'profitliteratura': profitliteratura,
        'profitother': profitother,
        'expensiveliteratura': expensiveliteratura,
        'tea': tea,
        'medal': medal,
        'postmail': postmail,
        'expensiveother': expensiveother,
      };

  // Создание объекта ProfitGroup из Map
  factory ProfitGroup.fromMap(Map<String, dynamic> map) {
    return ProfitGroup(
      date: map['date'].toDate(),
      sevenTraditioncash: map['sevenTraditioncash']?.toDouble(),
      sevenTraditioncard: map['sevenTraditioncard']?.toDouble(),
      profitliteratura: map['profitliteratura']?.toDouble(),
      profitother: map['profitother']?.toDouble(),
      expensiveliteratura: map['expensiveliteratura']?.toDouble(),
      tea: map['tea']?.toDouble(),
      medal: map['medal']?.toDouble(),
      postmail: map['postmail']?.toDouble(),
      expensiveother: map['expensiveother']?.toDouble(),
    );
  }

  // Функция сохранения данных в Firestore
  static void saveProfitGroups(List<ProfitGroup> profitGroups) async {
    ServiceUser? serviceUser = await getServiceUser();
    final String nameGroupCollection = serviceUser!.group;
    if (serviceUser.type.contains(ServiceName.chairperson) ||
        serviceUser.type.contains(ServiceName.treasurer)) {
      List<Map<String, dynamic>> data =
          profitGroups.map((group) => group.toJson()).toList();

      FirebaseFirestore.instance
          .collection(nameGroupCollection)
          .doc('namegroup_id')
          .collection('profitGroups')
          .doc('profitData')
          .set({
        'data': data,
      });
    }
  }

  // Функция загрузки данных из Firestore и преобразования их в список объектов ProfitGroup
  static Future<List<ProfitGroup>?> loadProfitGroups() async {
    ServiceUser? serviceUser = await getServiceUser();
    String? nameGroupCollection = serviceUser?.group;
    List<ProfitGroup> groups = [];
    if (isAutorization) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection(nameGroupCollection!)
          .doc('namegroup_id')
          .collection('profitGroups')
          .doc('profitData')
          .get();

      if (doc.exists) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

        if (data != null && data.containsKey('data')) {
          List<dynamic> jsonData = data['data'];

          groups = jsonData.map((json) => ProfitGroup.fromMap(json)).toList();
        }
        return groups;
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  // Для заполнения диалогового окна
  Map<String, dynamic> toMap() {
    return {
      '7 традиция нал': sevenTraditioncash,
      '7 традиция карта': sevenTraditioncard,
      'литература': profitliteratura,
      'другое': profitother,
      'книги': expensiveliteratura,
      'чай': tea,
      'медали': medal,
      'открытки': postmail,
      'прочее': expensiveother,
    };
  }

  void clear() async {
    sevenTraditioncash = null;
    sevenTraditioncard = null;
    profitliteratura = null;
    profitother = null;
    expensiveliteratura = null;
    tea = null;
    medal = null;
    postmail = null;
    expensiveother = null;
    await clearProfitGroups();
  }

  static Future<void> clearProfitGroups() async {
    ServiceUser? serviceUser = await getServiceUser();
    final String nameGroupCollection = serviceUser!.group;
    if (serviceUser.type.contains(ServiceName.chairperson) ||
        serviceUser.type.contains(ServiceName.treasurer)) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection(nameGroupCollection)
          .doc('namegroup_id')
          .collection('profitGroups')
          .get();
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        await FirebaseFirestore.instance
            .collection('profitGroups')
            .doc(doc.id)
            .delete();
      }
    }
  }

// Поиск по дате
  static ProfitGroup findProfitGroupByDate(
      List<ProfitGroup> list, DateTime targetDate) {
    return list.firstWhere(
      (profitGroup) => profitGroup.date.isAtSameMomentAs(targetDate),
      orElse: () => ProfitGroup(
          date: DateTime.now()), // Возвращает null, если объект не найден
    );
  }

// суммирование всех доходов и расходов за выбранный период
  static ProfitGroup? totalProfit(List<ProfitGroup> listProfitGroup) {
    if (listProfitGroup.isNotEmpty) {
      return ProfitGroup(
        date: listProfitGroup.last.date,
        sevenTraditioncash: listProfitGroup.fold(
            0,
            (previousValue, profitGroup) =>
                previousValue! + (profitGroup.sevenTraditioncash ?? 0)),
        sevenTraditioncard: listProfitGroup.fold(
            0,
            (previousValue, profitGroup) =>
                previousValue! + (profitGroup.sevenTraditioncard ?? 0)),
        profitliteratura: listProfitGroup.fold(
            0,
            (previousValue, profitGroup) =>
                previousValue! + (profitGroup.profitliteratura ?? 0)),
        profitother: listProfitGroup.fold(
            0,
            (previousValue, profitGroup) =>
                previousValue! + (profitGroup.profitother ?? 0)),
        expensiveliteratura: listProfitGroup.fold(
            0,
            (previousValue, profitGroup) =>
                previousValue! + (profitGroup.expensiveliteratura ?? 0)),
        tea: listProfitGroup.fold(
            0,
            (previousValue, profitGroup) =>
                previousValue! + (profitGroup.tea ?? 0)),
        medal: listProfitGroup.fold(
            0,
            (previousValue, profitGroup) =>
                previousValue! + (profitGroup.medal ?? 0)),
        postmail: listProfitGroup.fold(
            0,
            (previousValue, profitGroup) =>
                previousValue! + (profitGroup.postmail ?? 0)),
        expensiveother: listProfitGroup.fold(
            0,
            (previousValue, profitGroup) =>
                previousValue! + (profitGroup.expensiveother ?? 0)),
      );
    } else {
      return null;
    }
  }
}

///////// ************Класс для рабочки казначея*************////////////////
class Deductions {
  DateTime date;
  double? reserve;
  double? anniversary;
  double? rent;
  double? rc;
  double? rso;
  double? mosfond;
  double? fivetradition;
  double? balance;

  Deductions({
    required this.date,
    this.reserve,
    this.anniversary,
    this.rent,
    this.rc,
    this.rso,
    this.mosfond,
    this.fivetradition,
    this.balance,
  });
  // Преобразование объекта Deductions в Map
  Map<String, dynamic> toJson() => {
        'date': date,
        'reserve': reserve,
        'anniversary': anniversary,
        'rent': rent,
        'rc': rc,
        'rso': rso,
        'mosfond': mosfond,
        'fivetradition': fivetradition,
        'balance': balance,
      };

  // Создание объекта Deductions из Map
  factory Deductions.fromMap(Map<String, dynamic> map) {
    return Deductions(
      date: map['date'].toDate(),
      reserve: map['reserve']?.toDouble(),
      anniversary: map['anniversary']?.toDouble(),
      rent: map['rent']?.toDouble(),
      rc: map['rc']?.toDouble(),
      rso: map['rso']?.toDouble(),
      mosfond: map['mosfond']?.toDouble(),
      fivetradition: map['fivetradition']?.toDouble(),
      balance: map['balance']?.toDouble(),
    );
  }

  // Сохранение данных в Firestore в виде одного JSON объекта
  static void saveDeductions(List<Deductions> deductionsList) async {
    ServiceUser? serviceUser = await getServiceUser();
    final String nameGroupCollection = serviceUser!.group;
    if (serviceUser.type.contains(ServiceName.chairperson) ||
        serviceUser.type.contains(ServiceName.treasurer)) {
      List<Map<String, dynamic>> data =
          deductionsList.map((deductions) => deductions.toJson()).toList();

      FirebaseFirestore.instance
          .collection(nameGroupCollection)
          .doc('namegroup_id')
          .collection('deductions')
          .doc('deductionsData')
          .set({
        'data': data,
      });
    }
  }

  // Загрузка данных из Firestore и преобразование их в список объектов Deductions
  static Future<List<Deductions>> loadDeductions() async {
    ServiceUser? serviceUser = await getServiceUser();
    String? nameGroupCollection = serviceUser?.group;
    List<Deductions> deductionsList = [];
    if (isAutorization) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection(nameGroupCollection!)
          .doc('namegroup_id')
          .collection('deductions')
          .doc('deductionsData')
          .get();

      if (doc.exists) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

        if (data != null && data.containsKey('data')) {
          List<dynamic> jsonData = data['data'];

          deductionsList =
              jsonData.map((json) => Deductions.fromMap(json)).toList();
        }
      }
    }
    return deductionsList;
  }
}

///////// ************Модель данных для графика рабочих собраний*************////////////////
class WorkMeetingSchedule {
  int? numWeekOfMonth; // номер недели в месяце РАБОЧЕГО собрания
  int? numOfDay; // номер дня недели РАБОЧЕГО собрания
  List<String> selectedDays; // список выбранных дней собрания группы
  int?
      dayOfMonth; // номер недели в месяце РАБОЧЕГО собрания, если собрание определенного числа месяца
  bool? checkboxstatus;

  WorkMeetingSchedule({
    required this.numWeekOfMonth,
    required this.numOfDay,
    required this.selectedDays,
    this.dayOfMonth,
    this.checkboxstatus,
  });

  // Преобразование объекта WorkMeetingSchedule в Map
  Map<String, dynamic> toJson() => {
        'numWeekOfMonth': numWeekOfMonth,
        'numOfDay': numOfDay,
        'selectedDays': selectedDays,
        'dayOfMonth': dayOfMonth,
        'checkboxstatus': checkboxstatus,
      };

  // Создание объекта WorkMeetingSchedule из Map
  factory WorkMeetingSchedule.fromMap(Map<String, dynamic> map) {
    return WorkMeetingSchedule(
      numWeekOfMonth: map['numWeekOfMonth'],
      numOfDay: map['numOfDay'],
      selectedDays: List<String>.from(map['selectedDays']),
      dayOfMonth: map['dayOfMonth'],
      checkboxstatus: map['checkboxstatus'],
    );
  }

  // Функция сохранения данных в Firestore
  static void saveWorkMeetingSchedule(WorkMeetingSchedule schedule) async {
    ServiceUser? serviceUser = await getServiceUser();
    final String nameGroupCollection = serviceUser!.group;
    if (serviceUser.type.contains(ServiceName.chairperson)) {
      FirebaseFirestore.instance
          .collection(nameGroupCollection)
          .doc('namegroup_id')
          .collection('workMeetingSchedule')
          .doc('schedule')
          .set(schedule.toJson());
    }
  }

// Функция загрузки данных из Firestore и преобразования их в объект WorkMeetingSchedule
  static Future<WorkMeetingSchedule?> loadWorkMeetingSchedule() async {
    if (isAutorization) {
      ServiceUser? serviceUser = await getServiceUser();
      final String nameGroupCollection = serviceUser!.group;
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection(nameGroupCollection)
          .doc('namegroup_id')
          .collection('workMeetingSchedule')
          .doc('schedule')
          .get();

      if (doc.exists) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

        return WorkMeetingSchedule.fromMap(data!);
      } else {
        return null;
      }
    } else {
      return null;
    }
  }
}

///////// ************Класс Протокол РАБОЧЕГО собрания*************////////////////
class ProtocolWorkMeeting {
  DateTime date;
  int quorum;
  List<Map<String, Answers>> vote;
  String? text;

  ProtocolWorkMeeting({
    required this.date,
    required this.quorum,
    required this.vote,
    this.text,
  });

  factory ProtocolWorkMeeting.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> votesJson =
        json['vote'].cast<Map<String, dynamic>>();
    List<Map<String, Answers>> votes = votesJson.map((vote) {
      return {
        for (var key in vote.keys) key: Answers.fromJson(vote[key]),
      };
    }).toList();

    return ProtocolWorkMeeting(
      date: DateTime.parse(json['date']),
      quorum: json['quorum'],
      vote: votes,
      text: json['text'],
    );
  }

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> votesJson = vote.map((vote) {
      return {
        for (var key in vote.keys) key: vote[key]!.toJson(),
      };
    }).toList();

    return {
      'date': date.toIso8601String(),
      'quorum': quorum,
      'vote': votesJson,
      'text': text,
    };
  }

  static Future<void> saveProtocolWorkMeeting(
      ProtocolWorkMeeting protocol) async {
    ServiceUser? serviceUser = await getServiceUser();
    final String nameGroupCollection = serviceUser!.group;
    if (serviceUser.type.contains(ServiceName.chairperson)) {
      final collection = FirebaseFirestore.instance
          .collection(nameGroupCollection)
          .doc('namegroup_id')
          .collection('protocolWorkMeeting')
          .doc('protocolData');

      final doc = await collection.get();
      if (doc.exists && doc.data() != null) {
        List<dynamic> protocolJson = doc.data()!['protocols'];

        // Находим индекс протокола по дате
        int index = -1;
        for (int i = 0; i < protocolJson.length; i++) {
          if (compareDate(
              DateTime.parse(protocolJson[i]['date']), protocol.date)) {
            index = i;
            break;
          }
        }

        if (index != -1) {
          protocolJson[index] = protocol.toJson();
        } else {
          protocolJson.add(protocol.toJson());
        }

        await collection.set({'protocols': protocolJson});
      } else {
        await collection.set({
          'protocols': [protocol.toJson()]
        });
      }
    }
  }

  static Future<List<ProtocolWorkMeeting>?> loadProtocolWorkMeeting() async {
    if (isAutorization) {
      ServiceUser? serviceUser = await getServiceUser();
      final String nameGroupCollection = serviceUser!.group;
      final doc = await FirebaseFirestore.instance
          .collection(nameGroupCollection)
          .doc('namegroup_id')
          .collection('protocolWorkMeeting')
          .doc('protocolData')
          .get();

      if (doc.exists && doc.data() != null) {
        List<dynamic> protocolJson = doc.data()!['protocols'];
        // Преобразуем список Map в список ProtocolWorkMeeting
        return protocolJson
            .map((protocol) => ProtocolWorkMeeting.fromJson(protocol))
            .toList();
      } else {
        return [];
      }
    } else {
      return null;
    }
  }

  // Удаление из Firestore
  static Future<void> deleteProtocolWorkMeeting(
      ProtocolWorkMeeting protocol) async {
    ServiceUser? serviceUser = await getServiceUser();
    final String nameGroupCollection = serviceUser!.group;
    if (serviceUser.type.contains(ServiceName.chairperson)) {
      final docRef = FirebaseFirestore.instance
          .collection(nameGroupCollection)
          .doc('namegroup_id')
          .collection('protocolWorkMeeting')
          .doc('protocolData');

      final doc = await docRef.get();
      if (doc.exists && doc.data() != null) {
        List<dynamic> protocolJson = doc.data()!['protocols'];
        // Удаляем карту из списка
        protocolJson.removeWhere(
            (protocols) => compareDate(protocols['date'], protocol.date));
        await docRef.set({'protocols': protocolJson});
      }
    }
  }
}

class Answers {
  int support = 0;
  int against = 0;
  int abstained = 0;

  Answers({
    required this.support,
    required this.against,
    required this.abstained,
  });

  factory Answers.fromJson(Map<String, dynamic> json) {
    return Answers(
      support: json['support'],
      against: json['against'],
      abstained: json['abstained'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'support': support,
      'against': against,
      'abstained': abstained,
    };
  }
}

///////// ************Класс СЛУЖЕНИЙ*************////////////////
class ServiceCard {
  String id;
  String serviceName;
  String avatar;
  String name;
  String phone;

  ServiceCard({
    required this.id,
    required this.serviceName,
    required this.avatar,
    required this.name,
    required this.phone,
  });

  // Преобразование объекта ServiceCard в Map
  Map<String, dynamic> toJson() => {
        'id': id,
        'serviceName': serviceName,
        'avatar': avatar,
        'name': name,
        'phone': phone,
      };

  // Создание объекта ServiceCard из Map
  factory ServiceCard.fromMap(Map<String, dynamic> map) {
    return ServiceCard(
      id: map['id'],
      serviceName: map['serviceName'],
      avatar: map['avatar'],
      name: map['name'],
      phone: map['phone'],
    );
  }
  static Future<void> saveServiceCards(List<ServiceCard> serviceCards) async {
    ServiceUser? serviceUser = await getServiceUser();
    final String nameGroupCollection = serviceUser!.group;
    if (serviceUser.type.contains(ServiceName.chairperson)) {
      final collection = FirebaseFirestore.instance
          .collection(nameGroupCollection)
          .doc('namegroup_id')
          .collection('serviceCard')
          .doc('cardsData');

      // Преобразуем список ServiceCard в список Map
      List<Map<String, dynamic>> cardsJson =
          serviceCards.map((card) => card.toJson()).toList();

      // Сохраняем данные в Firestore
      await collection.set({'cards': cardsJson});
    }
  }

  static Future<List<ServiceCard>?> loadServiceCards() async {
    if (isAutorization) {
      ServiceUser? serviceUser = await getServiceUser();
      final String nameGroupCollection = serviceUser!.group;
      final doc = await FirebaseFirestore.instance
          .collection(nameGroupCollection)
          .doc('namegroup_id')
          .collection('serviceCard')
          .doc('cardsData')
          .get();

      if (doc.exists && doc.data() != null) {
        List<dynamic> cardsJson = doc.data()!['cards'];
        // Преобразуем список Map в список ServiceCard
        return cardsJson.map((card) => ServiceCard.fromMap(card)).toList();
      } else {
        return [];
      }
    } else {
      return null;
    }
  }

  // Обновление в Firestore
  static Future<void> updateServiceCard(ServiceCard serviceCard) async {
    ServiceUser? serviceUser = await getServiceUser();
    final String nameGroupCollection = serviceUser!.group;
    if (serviceUser.type.contains(ServiceName.chairperson)) {
      final docRef = FirebaseFirestore.instance
          .collection(nameGroupCollection)
          .doc('namegroup_id')
          .collection('serviceCard')
          .doc('cardsData');

      final doc = await docRef.get();
      if (doc.exists && doc.data() != null) {
        List<dynamic> cardsJson = doc.data()!['cards'];
        // Обновляем существующую карту в списке
        for (int i = 0; i < cardsJson.length; i++) {
          if (cardsJson[i]['id'] == serviceCard.id) {
            cardsJson[i] = serviceCard.toJson();
            break;
          }
        }
        await docRef.set({'cards': cardsJson});
      }
    }
  }

  // Удаление из Firestore
  static Future<void> deleteServiceCard(ServiceCard card) async {
    ServiceUser? serviceUser = await getServiceUser();
    final String nameGroupCollection = serviceUser!.group;
    if (serviceUser.type.contains(ServiceName.chairperson)) {
      final docRef = FirebaseFirestore.instance
          .collection(nameGroupCollection)
          .doc('namegroup_id')
          .collection('serviceCard')
          .doc('cardsData');

      final doc = await docRef.get();
      if (doc.exists && doc.data() != null) {
        List<dynamic> cardsJson = doc.data()!['cards'];
        // Удаляем карту из списка
        cardsJson.removeWhere((cards) => cards['id'] == card.id);
        await docRef.set({'cards': cardsJson});
      }
    }
  }

  // Удаление всех записей из Firestore
  Future<void> deleteAllServiceCards() async {
    ServiceUser? serviceUser = await getServiceUser();
    final String nameGroupCollection = serviceUser!.group;
    if (serviceUser.type.contains(ServiceName.chairperson)) {
      final docRef = FirebaseFirestore.instance
          .collection(nameGroupCollection)
          .doc('namegroup_id')
          .collection('serviceCard')
          .doc('cardsData');

      await docRef.set({'cards': []});
    }
  }

  // Виджет для отображения карточки
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(8.0),
        leading: CircleAvatar(
          radius: 50,
          backgroundImage: AssetImage(avatar),
        ),
        title: Text(
          serviceName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Name: $name\nPhone: $phone'),
      ),
    );
  }
}

///////// ************Класс Протокол собрания Ведущего*************////////////////

class ProtocolMeeting {
  DateTime date;
  String leadingName;
  List<Map<String, String>> themeMeeting;
  String? jubilee;
  String? newBie;
  String? newBieInGroup;
  String? upTo30days;
  double? expense;
  double? seventradition;
  double? literatura;
  int waspresent;

  ProtocolMeeting({
    required this.date,
    required this.leadingName,
    required this.themeMeeting,
    this.jubilee,
    this.newBie,
    this.newBieInGroup,
    this.upTo30days,
    this.expense,
    this.seventradition,
    this.literatura,
    required this.waspresent,
  });

  factory ProtocolMeeting.fromJSon(Map<String, dynamic> json) {
    List<Map<String, String>> themeMeetingList = [];
    List<dynamic> themeMeetingJson = json['themeMeeting'];
    for (var theme in themeMeetingJson) {
      Map<String, String> themeMap = {};
      theme.forEach((key, value) {
        themeMap[key] = value.toString();
      });
      themeMeetingList.add(themeMap);
    }
    return ProtocolMeeting(
      date: DateTime.parse(json['date']),
      leadingName: json['leadingName'],
      themeMeeting: themeMeetingList,
      jubilee: json['jubilee'],
      newBie: json['newBie'],
      newBieInGroup: json['newBieInGroup'],
      upTo30days: json['upTo30days'],
      expense: json['expense']?.toDouble(),
      seventradition: json['seventradition']?.toDouble(),
      literatura: json['literatura']?.toDouble(),
      waspresent: json['waspresent'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'leadingName': leadingName,
      'themeMeeting': themeMeeting,
      'jubilee': jubilee,
      'newBie': newBie,
      'newBieInGroup': newBieInGroup,
      'upTo30days': upTo30days,
      'expense': expense,
      'seventradition': seventradition,
      'literatura': literatura,
      'waspresent': waspresent,
    };
  }

// Сохранение протокола собрания
  static void saveProtocolMeetings(
      List<ProtocolMeeting> protocolMeetings) async {
    ServiceUser? serviceUser = await getServiceUser();
    final String nameGroupCollection = serviceUser!.group;
    if (serviceUser.type.contains(ServiceName.chairperson) ||
        serviceUser.type.contains(ServiceName.leading)) {
      List<Map<String, dynamic>> data =
          protocolMeetings.map((meeting) => meeting.toJson()).toList();

      FirebaseFirestore.instance
          .collection(nameGroupCollection)
          .doc('namegroup_id')
          .collection('protocolMeetings')
          .doc('meetingsData')
          .set({
        'data': data,
      });
    }
  }

// Загрузка протокола собрания
  static Future<List<ProtocolMeeting>?> loadProtocolMeetings() async {
    List<ProtocolMeeting> protocolMeetings = [];
    if (isAutorization) {
      ServiceUser? serviceUser = await getServiceUser();
      final String nameGroupCollection = serviceUser!.group;
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection(nameGroupCollection)
          .doc('namegroup_id')
          .collection('protocolMeetings')
          .doc('meetingsData')
          .get();

      if (doc.exists) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

        if (data != null && data.containsKey('data')) {
          List<dynamic> jsonData = data['data'];

          protocolMeetings =
              jsonData.map((json) => ProtocolMeeting.fromJSon(json)).toList();
        }
        return protocolMeetings;
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

// Поиск по дате
  static ProtocolMeeting? findProtocolMeetingByDate(
      List<ProtocolMeeting> listprotocol, DateTime selectedDate) {
    for (var protocolMeeting in listprotocol) {
      if (protocolMeeting.date.year == selectedDate.year &&
          protocolMeeting.date.month == selectedDate.month &&
          protocolMeeting.date.day == selectedDate.day) {
        return protocolMeeting;
      }
    }
    return null;
  }
}

//////////////////*****Класс Спикеров**************/////////////////////////////
class SpeakerMeeting {
  DateTime date;
  String speakerName;
  String? phone;
  String? homegroup;
  String? sobrietyPeriod;
  String? theme;

  SpeakerMeeting({
    required this.date,
    required this.speakerName,
    this.phone,
    this.homegroup,
    this.sobrietyPeriod,
    this.theme,
  });

  // Преобразование объекта SpeakerMeeting в Map
  Map<String, dynamic> toJson() => {
        'date': date,
        'speakerName': speakerName,
        'phone': phone,
        'homegroup': homegroup,
        'sobrietyPeriod': sobrietyPeriod,
        'theme': theme,
      };

  // Создание объекта SpeakerMeeting из Map
  factory SpeakerMeeting.fromMap(Map<String, dynamic> map) {
    return SpeakerMeeting(
      date: map['date'].toDate(),
      speakerName: map['speakerName'],
      phone: map['phone'],
      homegroup: map['homegroup'],
      sobrietyPeriod: map['sobrietyPeriod'],
      theme: map['theme'],
    );
  }

  static List<SpeakerMeeting> listFromJson(List<dynamic> json) {
    return json.map((meeting) => SpeakerMeeting.fromMap(meeting)).toList();
  }

  static List<Map<String, dynamic>> listToJson(List<SpeakerMeeting> meetings) {
    return meetings.map((meeting) => meeting.toJson()).toList();
  }

  static Future<void> saveMeetingsToFirestore(
      List<SpeakerMeeting> meetings) async {
    ServiceUser? serviceUser = await getServiceUser();
    final String nameGroupCollection = serviceUser!.group;
    if (serviceUser.type.contains(ServiceName.chairperson) ||
        serviceUser.type.contains(ServiceName.speaker)) {
      final firestore = FirebaseFirestore.instance
          .collection(nameGroupCollection)
          .doc('namegroup_id');
      final data = listToJson(meetings);

      await firestore
          .collection('speakerMeetings')
          .doc('all_meetings')
          .set({'meetings': data});
    }
  }

  static Future<void> deleteSpeakerMeetingFromFirestore(
      SpeakerMeeting meeting) async {
    if (isAutorization) {
      ServiceUser? serviceUser = await getServiceUser();
      final String nameGroupCollection = serviceUser!.group;
      final firestore = FirebaseFirestore.instance
          .collection(nameGroupCollection)
          .doc('namegroup_id');

      if (serviceUser.type.contains(ServiceName.chairperson) ||
          serviceUser.type.contains(ServiceName.speaker)) {
        final snapshot = await firestore
            .collection('speakerMeetings')
            .doc('all_meetings')
            .get();

        if (snapshot.exists) {
          final data = snapshot.data()!['meetings'];
          List<SpeakerMeeting> meetings =
              listFromJson(List<Map<String, dynamic>>.from(data));

          meetings.removeWhere((element) =>
              element.date == meeting.date &&
              element.speakerName == meeting.speakerName);

          final updatedData = listToJson(meetings);

          await firestore
              .collection('speakerMeetings')
              .doc('all_meetings')
              .set({'meetings': updatedData});
        }
      }
    }
  }

  static Future<List<SpeakerMeeting>?> loadMeetingsFromFirestore() async {
    if (isAutorization) {
      ServiceUser? serviceUser = await getServiceUser();
      final String nameGroupCollection = serviceUser!.group;
      final firestore = FirebaseFirestore.instance
          .collection(nameGroupCollection)
          .doc('namegroup_id');
      final snapshot = await firestore
          .collection('speakerMeetings')
          .doc('all_meetings')
          .get();

      if (snapshot.exists) {
        final data = snapshot.data()!['meetings'];
        return listFromJson(List<Map<String, dynamic>>.from(data));
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  // Поиск по дате
  static SpeakerMeeting? findSpeakerMeetingByDate(
      List<SpeakerMeeting> listspeaker, DateTime selectedDate) {
    for (var speakerMeeting in listspeaker) {
      if (speakerMeeting.date.year == selectedDate.year &&
          speakerMeeting.date.month == selectedDate.month &&
          speakerMeeting.date.day == selectedDate.day) {
        return speakerMeeting;
      }
    }
    return null;
  }
}

/////////////*************Класс библиотекаря **********////////////
class Book {
  String title;
  int quantity;

  Book(this.title, this.quantity);

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(map['title'], map['quantity']);
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'quantity': quantity,
    };
  }

  static List<Book> listFromJson(List<dynamic> json) {
    return json.map((book) => Book.fromMap(book)).toList();
  }

  static List<Map<String, dynamic>> listToJson(List<Book> books) {
    return books.map((book) => book.toMap()).toList();
  }

  static Future<void> saveBooksToFirestore(List<Book> books) async {
    ServiceUser? serviceUser = await getServiceUser();
    final String nameGroupCollection = serviceUser!.group;
    if (serviceUser.type.contains(ServiceName.chairperson) ||
        serviceUser.type.contains(ServiceName.librarian)) {
      final firestore = FirebaseFirestore.instance
          .collection(nameGroupCollection)
          .doc('namegroup_id');
      final data = listToJson(books);

      await firestore.collection('books').doc('all_books').set({'books': data});
    }
  }

  static Future<List<Book>?> loadBooksFromFirestore() async {
    if (isAutorization) {
      ServiceUser? serviceUser = await getServiceUser();
      final String nameGroupCollection = serviceUser!.group;
      final firestore = FirebaseFirestore.instance
          .collection(nameGroupCollection)
          .doc('namegroup_id');
      final snapshot =
          await firestore.collection('books').doc('all_books').get();

      if (snapshot.exists) {
        final data = snapshot.data()!['books'];
        return listFromJson(List<Map<String, dynamic>>.from(data));
      } else {
        return null;
      }
    } else {
      return null;
    }
  }
}

// Класс зарегистрированных юзеров
class ServiceUser {
  final String uid;
  final String email;
  List<ServiceName> type;
  final String group;
  final String name;

  ServiceUser(this.group, this.name,
      {required this.uid, required this.email, required this.type});

  static void saveServiceUserToFirestore(ServiceUser user) async {
    await FirebaseFirestore.instance
        .collection('service_users')
        .doc(user.email)
        .set({
      'uid': user.uid,
      'email': user.email,
      'type': user.type
          .map(
            (e) => e.toString().split('.').last,
          )
          .toList(),
      'group': user.group,
      'name': user.name,
    });
  }

  static Future<ServiceUser?> getServiceUserFromFirestore(String email) async {
    if (isAutorization) {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('service_users')
          .doc(email)
          .get();

      if (userSnapshot.exists) {
        Map<String, dynamic> userData =
            userSnapshot.data() as Map<String, dynamic>;
        List<ServiceName> userTypes = (userData['type'] as List<dynamic>)
            .map((e) => ServiceName.values.firstWhere(
                (enumValue) => enumValue.toString() == 'ServiceName.$e'))
            .toList();
        return ServiceUser(
          userData['group'],
          userData['name'],
          uid: userData['uid'],
          email: userData['email'],
          type: userTypes,
        );
      } else {
        return null;
      }
    } else {
      return null;
    }
  }
}

enum ServiceName {
  admin,
  chairperson,
  treasurer,
  tea,
  leading,
  speaker,
  librarian,
  user
}

String getServiceNameTranslation(ServiceName serviceName) {
  switch (serviceName) {
    case ServiceName.chairperson:
      return 'Председатель';
    case ServiceName.treasurer:
      return 'Казначей';
    case ServiceName.tea:
      return 'Чайханщик';
    case ServiceName.leading:
      return 'Ведущий';
    case ServiceName.speaker:
      return 'Спикерхантер';
    case ServiceName.librarian:
      return 'Библиотекарь';
    case ServiceName.user:
      return 'Пользователь';
    default:
      return '';
  }
}


////////// Класс групп ///////////////////////

class GroupsAA {
  final String name;
  final String city;
  final String area;
  final String? metro;
  final List<Map<String, String>>? timing;
  final List<Map<String, String>>? workmeeting;
  final List<Map<String, String>>? speaker;
  final String adress;
  final String? phone;
  final String? email;
  final String url;

  GroupsAA({
    required this.name,
    required this.city,
    required this.area,
    required this.adress,
    required this.url,
    this.metro,
    this.phone,
    this.email,
    this.timing,
    this.workmeeting,
    this.speaker,
  });

  factory GroupsAA.fromJson(Map<String, dynamic> json) {
    return GroupsAA(
      name: json['name'],
      city: json['city'],
      area: json['area'],
      adress: json['adress'],
      url: json['url'],
      metro: json['metro'],
      phone: json['phone'],
      email: json['email'],
      timing: List<Map<String, String>>.from(json['timing']),
      workmeeting: List<Map<String, String>>.from(json['workmeeting']),
      speaker: List<Map<String, String>>.from(json['speaker']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'city': city,
      'area': area,
      'metro': metro,
      'timing': timing,
      'workmeeting': workmeeting,
      'speaker': speaker,
      'adress': adress,
      'phone': phone,
      'email': email,
      'url': url,
    };
  }
}


// Функция транслитерации русских букв в латинские
// String transliterate(String input) {
//   Map<String, String> translitMap = {
//     'а': 'a',
//     'б': 'b',
//     'в': 'v',
//     'г': 'g',
//     'д': 'd',
//     'е': 'e',
//     'ё': 'yo',
//     'ж': 'zh',
//     'з': 'z',
//     'и': 'i',
//     'й': 'y',
//     'к': 'k',
//     'л': 'l',
//     'м': 'm',
//     'н': 'n',
//     'о': 'o',
//     'п': 'p',
//     'р': 'r',
//     'с': 's',
//     'т': 't',
//     'у': 'u',
//     'ф': 'f',
//     'х': 'kh',
//     'ц': 'ts',
//     'ч': 'ch',
//     'ш': 'sh',
//     'щ': 'shch',
//     'ъ': '',
//     'ы': 'y',
//     'ь': '',
//     'э': 'e',
//     'ю': 'yu',
//     'я': 'ya'
//   };

//   String result = '';

//   for (int i = 0; i < input.length; i++) {
//     String char = input[i].toLowerCase();
//     if (translitMap.containsKey(char)) {
//       result += translitMap[char]!;
//     } else {
//       result += char;
//     }
//   }

//   return result;
// }
