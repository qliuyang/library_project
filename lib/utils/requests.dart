import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

Future<http.StreamedResponse?> getOnlineDataBase() async {
  const url =
      'https://gitee.com/ly599575461/library_project/raw/main/assets/online/data.zip';
  try {
    final client = http.Client();
    final request = http.Request('GET', Uri.parse(url));
    final stream =
        client.send(request).timeout(const Duration(seconds: 5)); // 设置超时时间为5秒

    final response = await stream;
    if (response.statusCode == 200) {
      return response;
    } else {
      handleApiError(response.statusCode);
    }
  } on TimeoutException {
    handleApiError(-2, '请求超时');
  } catch (e) {
    handleApiError(-1, e.toString());
  }
  return null;
}

void handleApiError(int statusCode, [String? errorMessage]) {
  String message = '';
  switch (statusCode) {
    case -1:
      message = errorMessage ?? '未知错误';
      break;
    case -2:
      message = '请求超时';
      break;
    case 400:
      message = '请求无效';
      break;
    case 401:
      message = '未授权';
      break;
    case 404:
      message = '找不到资源';
      break;
    default:
      message = '服务器错误';
  }
  showErrorMessage("$message,您无法连接到Gitee服务器,使用软件自带的数据");
}

void showErrorMessage(String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.TOP,
    timeInSecForIosWeb: 10,
    backgroundColor: Colors.red,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}
