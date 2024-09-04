import 'package:flutter/material.dart';
import '../utils/online_sql.dart';

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
    return Text(processContent(text), style: style);
  }
}

class SimpleListWidget extends StatelessWidget {
  final List<Book> books;
  final void Function(Book) onBookSelected;

  const SimpleListWidget(
      {required this.books, required this.onBookSelected, super.key});

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return const Center(
        child: Text(''),
      );
    }

    return ListView.builder(
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final title = book.title;
        final author = book.author;

        return ListTile(
          title: Text(title),
          subtitle: Text(author),
          onTap: () => onBookSelected(book),
        );
      },
    );
  }
}

class InfiniteListWidget extends StatefulWidget {
  final Future<Book> Function(int itemCount) getBook;
  final Function(Book) onBookSelected;

  const InfiniteListWidget({
    super.key,
    required this.getBook,
    required this.onBookSelected,
  });

  @override
  State createState() => InfiniteListWidgetState();
}

class InfiniteListWidgetState extends State<InfiniteListWidget> {
  final int _singlePageItemCount = 9;
  List<Book> books = [];
  int itemCount = 1;
  bool isLoading = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !isLoading) {
        loadBooks();
      }
    });
    _init();
  }

  void _init() async {
    await Sql().init();
    var books_ = await Sql().getAllBooks();
    if (books_ == null) {
      loadBooks();
    } else {
      setState(() {
        books = books_;
      });
    }
  }

  Future<void> loadBooks() async {
    setState(() {
      isLoading = true;
    });
    int sqlBookCount = await Sql().getBookCount() + 1;
    int tempItemCount = sqlBookCount + itemCount + _singlePageItemCount;
    for (int i = sqlBookCount; i < tempItemCount; i++) {
      final tempBook = await widget.getBook(i);
      setState(() {
        books.add(tempBook);
      });
      Sql().storageBook(tempBook);
      itemCount++;
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: books.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= books.length) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        final book = books[index];
        return ListTile(
          title: Text(book.title),
          subtitle: Text(book.author),
          onTap: () => widget.onBookSelected(book),
        );
      },
    );
  }
}
