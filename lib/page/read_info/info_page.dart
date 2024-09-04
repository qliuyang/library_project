import 'package:flutter/material.dart';
import 'package:library_project/page/custom_widget.dart';
import 'read_page.dart';
import '../../utils/online_sql.dart';


class InfoPage extends StatelessWidget {
  final Book book;
  const InfoPage({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 20);

    void navigateToReadPage() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ReadPage(book: book)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("书名：${book.title}", style: textStyle),
              Text("作者: ${book.author}", style: textStyle),
              Text("字数：${book.fontNum}",
                  style: textStyle), // 假设 fontNum 是数值或字符串
              Text("分类：${book.classify}", style: textStyle),
              Text("章节数: ${book.chapterNum}", style: textStyle),
              Text("章节位置: ${book.chapterPos}", style: textStyle),
              ElevatedButton(
                onPressed: navigateToReadPage,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("开始阅读"),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ),
              ArticleText("描述: ${book.description}",
                  style: const TextStyle(fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}
