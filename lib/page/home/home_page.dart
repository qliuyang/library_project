import 'package:flutter/material.dart';
import '../read_info/info_page.dart';
import '../../utils/sql.dart';

import '../custom_widget.dart';

class _HomePage extends State<HomePage> {
  late BuildContext _context;
  List<Book> _books = [];

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  Future<void> _fetchBooks() async {
    final books = await Sql().getAllBooks();
    setState(() {
      _books = books;
    });
  }

  void navigateToInfoPage(Book book) {
    Navigator.push(
      _context,
      MaterialPageRoute(builder: (context) => InfoPage(book: book)),
    );
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    return Center(
        child: Column(children: [
      ListWidget(
        books: _books,
        onBookSelected: navigateToInfoPage,
      ),
    ]));
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePage();
}
