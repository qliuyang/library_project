import 'package:flutter/material.dart';
import '../read_info/info_page.dart';
import '../../utils/online_sql.dart';
import '../custom_widget.dart';

class _HomePage extends State<HomePage> {
  late BuildContext _context;

  @override
  void initState() {
    super.initState();
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
    return InfiniteListWidget(
        getBook: BookGetterYunShuWu().getBook,
        onBookSelected: navigateToInfoPage);
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePage();
}
