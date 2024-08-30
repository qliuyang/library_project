import 'package:flutter/material.dart';
import 'package:library_project/page/classify/classify_info_page.dart';
import '../../utils/sql.dart';

class ClassifyPage extends StatefulWidget {
  const ClassifyPage({super.key});
  @override
  State<ClassifyPage> createState() => _ClassifyPage();
}

class _ClassifyPage extends State<ClassifyPage> {
  late List<String> _classify;

  @override
  void initState() {
    super.initState();
  }

  Future<void> setClassify() async {
    _classify = await Sql().getClassify();
  }

  void showClassifyInfo(String classify) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassifyInfoPage(classify: classify),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分类'),
      ),
      body: FutureBuilder(
        future: setClassify(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 每行显示 2 个元素
                crossAxisSpacing: 15.0, // 水平间距
                mainAxisSpacing: 15.0, // 垂直间距
              ),
              itemCount: _classify.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    showClassifyInfo(_classify[index]);
                  },
                  child: Container(
                    width: 100.0, // 调整宽度+
                    height: 100.0, // 调整高度
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Center(
                      child: Text(
                        _classify[index],
                        style: const TextStyle(fontSize: 25),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('${snapshot.error}'),
            );
          }
          // 显示加载中
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}