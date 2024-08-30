import 'package:flutter/material.dart';
import '../../utils/sql.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../custom_widget.dart';

class ReadPage extends StatefulWidget {
  final Book book;
  const ReadPage({super.key, required this.book});

  @override
  State createState() => _ReadPageState();
}

class _ReadPageState extends State<ReadPage> {
  late int _bookId;
  String _content = '';
  String _bookTitle = '';
  String _chapterTitle = '';
  int _chapterchapterRowNum = 1;
  bool _isPureMode = true;
  late final ScrollController _scrollController;

  void togglePureMode() {
    setState(() {
      _isPureMode = !_isPureMode;
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadBookidAndTitle();
    _loadContent();
  }

  void _loadBookidAndTitle() {
    _bookId = widget.book.bookId;
    _bookTitle = widget.book.title;
  }

  Future<void> _loadContent() async {
    if (_chapterchapterRowNum > 1) {
      scrollToTop();
    }
    final chapter =
        await Sql().getBookChapterByID(_bookId, _chapterchapterRowNum);
    if (chapter == null) {
      return;
    }
    setState(() {
      _chapterTitle = chapter.title;
      _content = chapter.content;
    });
  }

  void _loadNextChapter() async {
    if (_chapterchapterRowNum >= widget.book.chapterNum) {
      return;
    }
    _chapterchapterRowNum++;
    await _loadContent();
  }

  void _loadLastChapter() async {
    if (_chapterchapterRowNum <= 1) {
      return;
    }
    _chapterchapterRowNum--;
    await _loadContent();
  }

  ElevatedButton buildChapterNavigationButton(IconData icon) {
    return ElevatedButton(
      onPressed:
          icon == Icons.arrow_forward ? _loadNextChapter : _loadLastChapter,
      style: ElevatedButton.styleFrom(
        fixedSize: const Size(90, 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
      ),
      child: Icon(icon),
    );
  }

  void scrollToTop() async {
    await _scrollController.animateTo(0,
        duration: const Duration(seconds: 1), curve: Curves.easeInOut);
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(_bookTitle),
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      actions: [
        IconButton(
          icon: Icon(_isPureMode ? Icons.view_list : Icons.view_quilt),
          onPressed: togglePureMode,
        ),
      ],
    );
  }

  AnimatedContainer _buildBottomAppBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isPureMode ? 0 : 60,
      child: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            buildChapterNavigationButton(Icons.arrow_back),
            buildChapterNavigationButton(Icons.arrow_forward),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: scrollToTop,
        tooltip: '回到顶部',
        child: const Icon(Icons.arrow_upward),
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.globalPosition.dx > 0) {
            _loadNextChapter(); // 向右滑动，加载上一章
          } else {
            _loadLastChapter(); // 向左滑动，加载下一章
          }
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AutoSizeText(
                  style: const TextStyle(
                      fontSize: 30, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  _chapterTitle,
                ),
                ArticleText(
                  _content,
                  style: const TextStyle(fontSize: 25),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }
}
