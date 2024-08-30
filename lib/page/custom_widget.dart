import 'package:flutter/material.dart';
import '../utils/sql.dart';

class ArticleText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const ArticleText(this.text, {super.key, this.style});

  String processContent(String content) {
    content = content.replaceAll('    ', '\n　　');
    content = content.replaceAll('　　', '\n　　');
    return content;
  }

  @override
  Widget build(BuildContext context) {
    return Text(processContent(text),style: style);
  }
}

class ListWidget extends StatelessWidget {
  final List<Book> books;
  final Function(Book) onBookSelected;
  const ListWidget(
      {super.key, required this.books, required this.onBookSelected});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return ListTile(
            title: Text(book.title),
            subtitle: Text(book.author),
            onTap: () => onBookSelected(book),
          );
        },
      ),
    );
  }
}
