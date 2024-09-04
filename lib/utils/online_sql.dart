import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:xpath_selector/xpath_selector.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Book {
  final int bookId;
  final String title;
  final String author;
  final String fontNum;
  final int chapterNum;
  final String classify;
  final int chapterPos;
  final String description;

  Book({
    required this.bookId,
    required this.title,
    required this.author,
    required this.fontNum,
    required this.chapterNum,
    required this.classify,
    required this.chapterPos,
    required this.description,
  });

  @override
  String toString() {
    return "Book(bookId: $bookId, title: $title, author: $author, fontNum: $fontNum, chapterNum: $chapterNum, classify: $classify, chapterPos: $chapterPos, description: $description)";
  }

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'title': title,
      'author': author,
      'fontNum': fontNum,
      'chapterNum': chapterNum,
      'classify': classify,
      'chapterPos': chapterPos,
      'description': description,
    };
  }
}

class Chapter {
  final int chapterPos;
  final String title;
  final String content;

  Chapter({
    required this.chapterPos,
    required this.title,
    required this.content,
  });
  @override
  String toString() {
    return "Chapter(chapterPos: $chapterPos, title: $title, content: $content)";
  }

  Map<String, dynamic> toMap() {
    return {
      'chapterPos': chapterPos,
      'title': title,
      'content': content,
    };
  }
}

abstract class BookGetter {
  String baseUrl;
  BookGetter({required this.baseUrl});

  String joinUrl(String baseUrl, String url) {
    bool baseHasTrailingSlash = baseUrl.endsWith('/');
    bool urlStartsWithSlash = url.startsWith('/');

    if (baseHasTrailingSlash && urlStartsWithSlash) {
      return baseUrl + url.substring(1);
    } else if (!baseHasTrailingSlash && !urlStartsWithSlash) {
      return '$baseUrl/$url';
    } else {
      return baseUrl + url;
    }
  }

  Future<String> readUrl(String url) async {
    try {
      var content = await get(Uri.parse(url));
      if (content.statusCode != 200) {
        _showToast('Error reading url: $url');
      }
      return content.body;
    } catch (e) {
      _showToast(e.toString());
    }
    return '';
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<Book> getBook(int bookId);
  Future<Chapter> getChapter(int chapterPos);
}

class BookGetterYunShuWu extends BookGetter {
  static final BookGetterYunShuWu _instance = BookGetterYunShuWu._internal();
  factory BookGetterYunShuWu() => _instance;

  late String bookUrl;
  late String searchUrl;
  late String chapterUrl;
  late String classifyUrl;

  final String infoPath = '//div[2]/div/div[2]/ul/li[1]/div[1]/div[2]/p';
  final String titlePath = '//div[2]/div/div[1]';

  final String bookChapterContentPath = '//div[1]/div[4]/div/p[3]';
  final String bookChapterTitlePath = '//div[1]/div[4]/div/p[2]';
  final String chapterPosPath = '//div[2]/div/div[2]/ul/li[1]/div[2]/a[1]';

  final String searchResultPath = '//div[3]/div/div/ul/li/a';
  final String descriptionPath = "//meta[@name='description']";
  final String classifyPath = '//div[2]/div/ul/li/a';
  final String classifyResult = '//div[2]/div[1]/div/ul/li/a';

  final RegExp infoPattern = RegExp(r'分类:(.+?)作者:(.+?)(\d+\.\d+万字)共(\d+)章');
  final RegExp searchResultPattern = RegExp(r'/book/(\d+)\.html');
  final RegExp chapterPosPattern = RegExp(r'/chap/(\d+)\.html');

  BookGetterYunShuWu._internal() : super(baseUrl: 'https://yunshuwu.cn/') {
    bookUrl = joinUrl(baseUrl, 'book/');
    chapterUrl = joinUrl(baseUrl, 'chap/');
    searchUrl = joinUrl(baseUrl, 'stack/book/');
    searchUrl = joinUrl(baseUrl, 'cates');
  }

  String getClassifyBookUrl(String classifyHref) {
    return joinUrl(baseUrl, classifyHref);
  }

  List<String> workXpathGetText(HtmlXPath content, String path,
      {String? attr}) {
    final tempResult = content.queryXPath(path);
    final List<String> result = [];
    for (XPathNode node in tempResult.nodes) {
      if (attr != null) {
        result.add(cleanText(node.attributes[attr]!));
      } else {
        result.add(cleanText(node.text!));
      }
    }
    return result;
  }

  String cleanText(String text) {
    return text.replaceAll(RegExp(r'\s+'), '');
  }

  String getBookTitle(HtmlXPath content) {
    return workXpathGetText(content, titlePath).first;
  }

  String getBookInfoText(HtmlXPath content) {
    return workXpathGetText(content, infoPath).first;
  }

  String getBookDescription(HtmlXPath content) {
    return workXpathGetText(content, descriptionPath, attr: 'content').first;
  }

  String getBookChapterPosition(HtmlXPath content) {
    return workXpathGetText(content, chapterPosPath, attr: 'href').first;
  }

  String getChapterTitle(HtmlXPath content) {
    return workXpathGetText(content, bookChapterTitlePath).first;
  }

  String getChapterContent(HtmlXPath content) {
    return workXpathGetText(content, bookChapterContentPath).first;
  }

  List<(String, String)> getClassifyListText(HtmlXPath content) {
    final hrefList = workXpathGetText(content, classifyPath, attr: 'href');
    final classifyNameList = workXpathGetText(content, classifyPath);

    final List<(String, String)> result =
        List.generate(hrefList.length, (index) {
      final href = hrefList[index];
      final classifyName = classifyNameList[index];
      return (classifyName, href);
    });

    return result;
  }

  List<String> getClassifyResultText(HtmlXPath content) {
    return workXpathGetText(content, classifyResult, attr: 'href');
  }

  @override
  Future<Book> getBook(int bookId) async {
    // 书的初始信息
    final String bookUrlWithId = joinUrl(bookUrl, '$bookId.html');
    final HtmlXPath bookContent = HtmlXPath.html(await readUrl(bookUrlWithId));

    // 获取一个p里书的信息
    var bookInfoText = getBookInfoText(bookContent);
    final match = infoPattern.firstMatch(bookInfoText);
    if (match == null) {
      throw Exception('Book info not found');
    }
    final classify = match.group(1)!;
    final author = match.group(2)!;
    final fontNum = match.group(3)!;
    final chapterNum = int.parse(match.group(4)!);

    // 获取Title
    final title = getBookTitle(bookContent);
    // 获取Description
    final description = getBookDescription(bookContent);
    // 获取章节位置
    final chapterPosTemp = getBookChapterPosition(bookContent);
    final chapterPos =
        int.parse(chapterPosPattern.firstMatch(chapterPosTemp)!.group(1)!);

    return Book(
      bookId: bookId,
      title: title,
      description: description,
      classify: classify,
      author: author,
      fontNum: fontNum,
      chapterNum: chapterNum,
      chapterPos: chapterPos,
    );
  }

  @override
  Future<Chapter> getChapter(int chapterPos) async {
    // 章节的初始信息
    final String chapterUrlWithId = joinUrl(chapterUrl, '$chapterPos.html');
    final HtmlXPath chapterContent =
        HtmlXPath.html(await readUrl(chapterUrlWithId));

    // 章节信息
    final chapterTitle = getChapterTitle(chapterContent);
    final chapterContentText = getChapterContent(chapterContent);

    return Chapter(
        chapterPos: chapterPos,
        title: chapterTitle,
        content: chapterContentText);
  }

  Future<List<Book>> getClassifyBooks(String classifyHref) async {
    final classifyBookUrl = getClassifyBookUrl(classifyHref);
    final HtmlXPath classifyContent =
        HtmlXPath.html(await readUrl(classifyBookUrl));
    final bookIdList = getResultBookId(classifyContent, classifyResult);
    final List<Book> result = await Future.wait(
      bookIdList.map((int bookId) async {
        final book = await getBook(bookId);
        return book;
      }),
    );
    return result;
  }

  Future<List<(String, String)>> getClassifyList() async {
    final HtmlXPath classifyContent =
        HtmlXPath.html(await readUrl(classifyUrl));
    return getClassifyListText(classifyContent);
  }

  List<int> getResultBookId(HtmlXPath content, String path) {
    final List<String> urls = workXpathGetText(content, path, attr: 'href');
    final List<int> result = urls.map((String url) {
      return int.parse(searchResultPattern.firstMatch(url)!.group(1)!);
    }).toList();
    return result;
  }

  Future<List<Book>> searchBookByName(String bookName) async {
    final String searchUrlWithId =
        joinUrl(searchUrl, 'search.html?kw=$bookName');
    final HtmlXPath searchContent =
        HtmlXPath.html(await readUrl(searchUrlWithId));
    final bookIds = getResultBookId(searchContent, searchResultPath);

    final List<Book> result = await Future.wait(
      bookIds.map((int bookId) async {
        final book = await getBook(bookId);
        return book;
      }),
    );
    return result;
  }
}

class Sql {
  late Database _database;
  static final Sql _instance = Sql._internal();

  factory Sql() => _instance;

  Sql._internal();

  Future<bool> init() async {
    Directory? directory = await getExternalStorageDirectory();
    if (directory == null) {
      return false;
    }
    File dbPath = File(join(directory.path, 'data.db'));
    try {
      _database = await openDatabase(
        dbPath.path,
        version: 1,
        onCreate: (db, version) => {
          db.execute('''
          CREATE TABLE "Books"
            (
                id INTEGER not null primary key autoincrement,
                title      TEXT    not null,
                author     TEXT    not null,
                fontNum    TEXT,
                chapterNum integer,
                classify   TEXT,
                chapterPos integer
            , bookId integer, description integer
            )
        ''')
        },
      );
    } catch (e) {
      return false;
    }
    return true;
  }

  Future<List<String>> getClassify() async {
    const query = 'SELECT DISTINCT classify FROM Books';
    final results = await _database.rawQuery(query);
    return results.map((map) => map['classify'] as String).toList();
  }

  Future<void> storageInfo(String tableName, Map<String, dynamic> info) async {
    final columns = info.keys.join(', ');
    final placeholders = List.generate(info.length, (_) => '?').join(', ');
    final sql = 'INSERT INTO $tableName ($columns) VALUES ($placeholders)';
    await _database.rawInsert(sql, info.values.toList());
  }

  Future<void> storageBook(Book book) async {
    await storageInfo('Books', book.toMap());
  }

  Future<int> getBookCount() async {
    final result = await _database.rawQuery('SELECT COUNT(*) FROM Books');
    return result.first.values.first as int;
  }

  Future<List<Book>?> getAllBooks() async {
    const query = 'SELECT * FROM Books';
    final results = await _database.rawQuery(query);
    if (results.isEmpty) {
      return null;
    }
    return results
        .map((map) => Book(
              bookId: map['bookId'] as int,
              description: map['description'] as String,
              title: map['title'] as String,
              author: map['author'] as String,
              fontNum: map['fontNum'] as String,
              chapterNum: map['chapterNum'] as int,
              classify: map['classify'] as String,
              chapterPos: map['chapterPos'] as int,
            ))
        .toList();
  }
}
