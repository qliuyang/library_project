import 'dart:async';

import 'package:flutter/material.dart';
import 'package:library_project/page/read_info/info_page.dart';
import '../../utils/sql.dart';
import '../custom_widget.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Book> _searchResults = [];

  // Debounce mechanism to minimize database calls
  Timer? _debounce;

  void _onSearchTextChanged(String value) {
    // Reset debounce timer
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchAsync(value);
    });
  }

  Future<void> _searchAsync(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return; // No search term, clear results
    }

    final results = await Sql().searchBook(query);
    setState(() {
      _searchResults = results;
    });
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
      appBar: AppBar(title: const Text('海量书籍搜索')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: "输入关键字(书名/作者)..."),
              onChanged: _onSearchTextChanged,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Column(children: [
                ListWidget(
                  books: _searchResults,
                  onBookSelected: navigateToInfoPage,
                )
              ]),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose(); // Clean up the controller
    _debounce?.cancel(); // Cancel any ongoing timer
    super.dispose();
  }
}
