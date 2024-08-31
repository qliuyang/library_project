import 'dart:async';
import 'dart:io';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:permission_handler/permission_handler.dart';
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

  Future<void> extractDBFileFromZip(
      Uint8List zipUintList, File extractedDbPath) async {
    final archive = ZipDecoder().decodeBytes(zipUintList);
    for (final file in archive) {
      if (file.name == 'data.db') {
        final dbBytes = file.content as Uint8List;
        await extractedDbPath.writeAsBytes(dbBytes);
        break;
      }
    }
  }

  Future<bool> compareIsSameFileSize(File file, Uint8List data) async {
    var dbFileSize = (await file.length()).toInt();
    var zipDataSize = data.lengthInBytes;
    return dbFileSize == zipDataSize;
  }

  Future<bool> init() async {
    await _requestStoragePermission();
    final directory = await getExternalStorageDirectory();
    if (directory == null) {
      return false;
    }

    StreamedResponse? onlineDatabase = await getOnlineDataBase();
    Uint8List zipUintList = onlineDatabase != null
        ? await onlineDatabase.stream.toBytes()
        : (await rootBundle.load('assets/offline/data.zip'))
            .buffer
            .asUint8List();

    // 来自网络或者内部zip
    File zipTempFile = File(join(directory.path, 'temp_data.zip'));
    // 软件直接读取的db
    File dbPath = File(join(directory.path, 'data.db'));

    // 存储临时压缩包
    if (await zipTempFile.exists()) {
      if (!await compareIsSameFileSize(zipTempFile, zipUintList)) {
        zipTempFile.writeAsBytes(zipUintList);
      }
    } else {
      zipTempFile.writeAsBytes(zipUintList);
    }

    // 直接读取的db不在
    if (!await dbPath.exists()) {
      await extractDBFileFromZip(zipUintList, dbPath);
    } else {
      // 直接读取的db在，先解压到temp_data.db
      final extractedTempDbPath = File(join(directory.path, 'temp_data.db'));
      await extractDBFileFromZip(zipUintList, extractedTempDbPath);
      // 对比是否一样，不一样用网络下载的
      bool isSame = await compareIsSameFileSize(
          dbPath, await extractedTempDbPath.readAsBytes());
      if (!isSame) {
        await dbPath.delete();
        await extractedTempDbPath.rename(dbPath.path);
      } else {
        await extractedTempDbPath.delete();
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

    if (results.isNotEmpty && chapterRowNum < results.length) {
      final chapterMap = results[chapterRowNum];
      return Chapter(
        bookId: chapterMap['bookId'] as int,
        title: chapterMap['title'] as String,
        content: chapterMap['content'] as String,
      );
    }

    return null;
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
