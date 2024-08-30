import 'package:library_project/page/read_info/info_page.dart';
import 'package:library_project/utils/sql.dart';
import '../custom_widget.dart';
import 'package:flutter/material.dart';

class ClassifyInfoPage extends StatefulWidget {
  const ClassifyInfoPage({super.key, required this.classify});
  final String classify;

  @override
  State createState() => _ClassifyInfoPage();
}

class _ClassifyInfoPage extends State<ClassifyInfoPage> {
  late List<Book> _classifyInfo;

  Future<void> setClassifyInfo() async {
    _classifyInfo = await Sql().searchBook(widget.classify);
  }

  void navigateToInfoPage(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => InfoPage(book: book)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classify),
      ),
      body: FutureBuilder(
        future: setClassifyInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(children: [
              ListWidget(
                books: _classifyInfo,
                onBookSelected: navigateToInfoPage,
              )
            ]);
          } else if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          // 显示加载中状态
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
