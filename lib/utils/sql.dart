import 'dart:async';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:archive/archive.dart';
import 'requests.dart';

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
}

class Chapter {
  final int bookId;
  final String title;
  final String content;

  Chapter({
    required this.bookId,
    required this.title,
    required this.content,
  });
}

class Sql {
  late Database _database;
  static final Sql _instance = Sql._internal();

  factory Sql() => _instance;

  Sql._internal();

  Future<void> _requestStoragePermission() async {
    final status = await Permission.storage.request();
    if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  Future<void> extractZip(Uint8List zipByte, File targetFilePath) async {
    final archive = ZipDecoder().decodeBytes(zipByte.buffer.asUint8List());
    for (final file in archive) {
      final fileContent = file.content as List<int>;
      await targetFilePath.writeAsBytes(fileContent);
    }
  }

  Future<bool> compareIsSameFileSize(File dbFile, Uint8List zipData) async {
    var dbFileSize = (await dbFile.length()).toInt();
    var zipDataSize = zipData.lengthInBytes;

    return dbFileSize == zipDataSize;
  }

  Future<bool> init() async {
    await _requestStoragePermission();
    final directory = await getExternalStorageDirectory();
    if (directory == null) {
      return false;
    }

    StreamedResponse? onlineDatabase = await getOnlineDataBase();
    Uint8List zipUintList;

    if (onlineDatabase == null) {
      zipUintList = (await rootBundle.load('assets/offline/data.zip')).buffer.asUint8List();
    } else {
      zipUintList = await onlineDatabase.stream.toBytes();
    }

    File dbPath = File(join(directory.path, 'data.db'));

    if (!await dbPath.exists()) {
      await extractZip(zipUintList, dbPath);
    } else {
      if (await compareIsSameFileSize(dbPath, zipUintList)) {
        return true;
      } else {
        await extractZip(zipUintList, dbPath);
      }
    }
    _database = await openDatabase(dbPath.path, version: 1);
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

  Future<List<Book>> searchBook(String keyword) async {
    const query =
        'SELECT * FROM Books WHERE title LIKE ? OR author LIKE ? OR classify LIKE ?';
    final arguments = ['%$keyword%', '%$keyword%', '%$keyword%'];
    final List<Map<String, dynamic>> bookMap =
        await _database.rawQuery(query, arguments);

    return bookMap
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

  Future<Chapter?> getBookChapterByID(int bookId, int chapterRowNum) async {
    const query = 'SELECT * FROM Chapters WHERE bookId = ?';
    final results = await _database.rawQuery(query, [bookId]);

    // Ensure results are available and index is valid
    if (results.isNotEmpty && chapterRowNum < results.length) {
      final chapterMap = results[chapterRowNum];

      return Chapter(
        bookId: chapterMap['bookId'] as int,
        title: chapterMap['title'] as String,
        content: chapterMap['content'] as String,
      );
    }

    return null; // Return null if no chapter found
  }

  Future<List<Book>> getAllBooks() async {
    const query = 'SELECT * FROM Books';
    final results = await _database.rawQuery(query);

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
