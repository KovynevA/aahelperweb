import 'package:aahelper/helper/stylemenu.dart';
import 'package:aahelper/helper/utils.dart';
import 'package:aahelper/service/librarian/medal.dart';
import 'package:flutter/material.dart';

class Librarian extends StatefulWidget {
  final String title;

  const Librarian({super.key, required this.title});

  @override
  State<Librarian> createState() => _LibrarianState();
}

class _LibrarianState extends State<Librarian>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> tabname = ['Литература', 'Медали'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabname.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        title: Text(widget.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: List.generate(
              _tabController.length, (index) => Tab(text: tabname[index])),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          LibrarianWidget(),
          MedalWidget(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class LibrarianWidget extends StatefulWidget {
  const LibrarianWidget({super.key});

  @override
  State<LibrarianWidget> createState() => _LibrarianWidgetState();
}

class _LibrarianWidgetState extends State<LibrarianWidget> {
  List<Book> books = [];
  List<TextEditingController> quantityControllers = [];
  ServiceUser? serviceuser;

  @override
  void initState() {
    getServiceUser();
    Book.loadBooksFromFirestore().then((value) {
      setState(() {
        books = value ?? [];
        quantityControllers = List.generate(
            books.length,
            (index) =>
                TextEditingController(text: books[index].quantity.toString()));
        if (books.isEmpty) {
          books.add(Book('БК', 0));
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

  void addBook() {
    setState(() {
      books.add(Book('БК', 0));
      quantityControllers.add(TextEditingController(text: '0'));
    });
  }

  void removeBook() {
    setState(() {
      if (books.isNotEmpty) {
        books.removeLast();
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
              IconButton(onPressed: addBook, icon: const Icon(Icons.add_box)),
              IconButton(
                onPressed: removeBook,
                icon: const Icon(Icons.remove_circle),
              ),
            ],
          ),
          ListView.builder(
            shrinkWrap: true,
            itemCount: books.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TreasureDropdownButton(
                      decoration: Decor.decorDropDownButton,
                      value: books[index].title,
                      items: const [
                        'БК',
                        "БК с историями",
                        "БК мини",
                        'ЕР',
                        '12х12',
                        'Жить трезвым',
                        'КЭВБ',
                        'Язык сердца',
                        'Пришли к убеждению',
                        'Д.Боб и ветераны',
                      ],
                      onChanged: (String? value) {
                        setState(() {
                          books[index].title = value!;
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
                          books[index].quantity = int.tryParse(value) ?? 0;
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
              Book.saveBooksToFirestore(books);
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
