import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:purebook/common/LoadDialog.dart';
import 'package:purebook/common/ReaderPageAgent.dart';
import 'package:purebook/common/Screen.dart';
import 'package:purebook/common/common.dart';
import 'package:purebook/common/toast.dart';
import 'package:purebook/common/util.dart';
import 'package:purebook/entity/BookInfo.dart';
import 'package:purebook/entity/BookTag.dart';
import 'package:purebook/entity/Chapter.dart';
import 'package:purebook/entity/ReadPage.dart';

class ReadModel with ChangeNotifier {
  BookInfo bookInfo;

  //本书记录
  BookTag bookTag;
  ReadPage prePage;
  ReadPage curPage;
  ReadPage nextPage;
  List<Widget> allContent = [];

  //页面控制器
  PageController pageController;

  //章节slider value
  double value;

  //背景色数据
  List<List> bgs = [
    [246, 242, 234],
    [242, 233, 209],
    [231, 241, 231],
    [228, 239, 242],
    [242, 228, 228],
  ];

  //页面字体大小
  double fontSize = 27.0;

  //显示上层 设置
  bool showMenu = false;

  //背景色索引
  int bgIdx = 0;

  //页面宽高
  double contentH;
  double contentW;

  //页面上下文
  BuildContext context;

//是否修改font
  bool font = false;

  //获取本书记录
  getBookRecord() async {
    showMenu = false;
    if (SpUtil.haveKey(bookInfo.Id)) {
      bookTag = BookTag.fromJson(jsonDecode(SpUtil.getString(bookInfo.Id)));
      //书的最后一章
      if (bookInfo.CId == "-1") {
        bookTag.cur = bookTag.chapters.length - 1;
      }
      getChapters();
      intiPageContent(bookTag.cur, false);
      pageController = PageController(initialPage: bookTag.index);
      value = bookTag.cur.toDouble();
      notifyListeners();
      //本书已读过
    } else {
      bookTag = BookTag.bookName(bookInfo.Name);
      if (SpUtil.haveKey('${bookInfo.Id}chapters')) {
        var string = SpUtil.getString('${bookInfo.Id}chapters');
        List v = jsonDecode(string);
        bookTag.chapters = v.map((f) => Chapter.fromJson(f)).toList();
      }
      pageController = PageController(initialPage: 1);
      getChapters().then((_) {
        if (bookInfo.CId == "-1") {
          bookTag.cur = bookTag.chapters.length - 1;
        }
        intiPageContent(bookTag.cur, false);
      });
    }
  }

  Future intiPageContent(int idx, bool jump) async {
    showGeneralDialog(
      context: context,
      barrierLabel: "",
      barrierDismissible: true,
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (BuildContext context, Animation animation,
          Animation secondaryAnimation) {
        return LoadingDialog();
      },
    );
    prePage = await loadChapter(idx - 1);
    curPage = await loadChapter(idx);
    nextPage = await loadChapter(idx + 1);
    Navigator.pop(context);

    print('refresh ok');
    fillAllContent();
    value = bookTag.cur.toDouble();
    if (jump) {
      int ix = prePage?.pageOffsets?.length ?? 0;
      print(ix);

      print("jump 1");
      pageController.jumpToPage(ix);
    }
  }

  changeChapter(int idx) async {
    bookTag.index = idx;
    int preLen = prePage == null ? 0 : prePage.pageOffsets.length;
    int curLen = curPage == null ? 0 : curPage.pageOffsets.length;
    if ((idx + 1 - preLen) > (curLen)) {
      int temp = bookTag.cur + 1;
      if (temp >= bookTag.chapters.length) {
        return;
      } else {
        bookTag.cur += 1;
        prePage = curPage;
        curPage = nextPage;
        nextPage = await loadChapter(bookTag.cur + 1);
        print("next chapter");
        fillAllContent();
        print("jump 2");
        pageController.jumpToPage(prePage?.pageOffsets?.length ?? 0);
      }
    } else if (idx < preLen) {
      print("pre chapter");
      int temp = bookTag.cur - 1;
      if (temp < 0) {
        return;
      } else {
        bookTag.cur -= 1;
        nextPage = curPage;
        curPage = prePage;
        prePage = await loadChapter(bookTag.cur - 1);
        print("pre chapter");
        fillAllContent();
        int ix = (prePage?.pageOffsets?.length ?? 0) +
            curPage.pageOffsets.length -
            1;
        print("jump 3");
        pageController.jumpToPage(ix);
//        notifyListeners();
      }
    }
  }

  switchBgColor(i) {
    bgIdx = i;
    notifyListeners();
  }

  Future getChapters() async {
    var url = Common.chaptersUrl +
        '/${bookInfo.Id}/${bookTag?.chapters?.length ?? 0}';
    var ctx;
    if (bookTag.chapters.length == 0 && context != null) {
      ctx = context;
      Toast.show('加载目录...');
    }
    Response response = await Util(ctx).http().get(url);
    print('chapters init ok');
    List data = response.data['data'];
    if (data == null) {
      return;
    }
    print(data.length.toString());
    List<Chapter> list = data.map((c) => Chapter.fromJson(c)).toList();
    bookTag.chapters.addAll(list);
    //书的最后一章
    if (bookInfo.CId == "-1") {
      bookTag.cur = bookTag.chapters.length - 1;
      value = bookTag.cur.toDouble();
    }
  }

  Future<ReadPage> loadChapter(int idx) async {
    ReadPage r = new ReadPage();
    if (idx < 0) {
      r.chapterName = "封面";
      r.pageOffsets = List(1);
      r.chapterContent = "没有更多内容,AD";
      return r;
    } else if (idx == bookTag.chapters.length) {
      r.chapterName = "等待作者更新";
      r.pageOffsets = List(1);
      r.chapterContent = "没有更多内容,AD";
      return r;
    }

    r.chapterName = bookTag.chapters[idx].name;
    String id = bookTag.chapters[idx].id;
    if (!SpUtil.haveKey(id)) {
      String url = Common.bookContentUrl + '/$id';
      print(id);

      Response v = await Util(null).http().get(url);

      r.chapterContent = v.data['data']['content'].toString().trim();
      //缓存章节
      SpUtil.putString(id, r.chapterContent);
      //缓存章节分页
      r.pageOffsets = ReaderPageAgent.getPageOffsets(
          r.chapterContent, contentH, contentW, fontSize);
      SpUtil.putString('pages' + id, r.pageOffsets.join('-'));
      bookTag.chapters[idx].hasContent = 2;
    } else {
      r.chapterContent = SpUtil.getString(id);
      if (SpUtil.haveKey('pages' + id)) {
        r.pageOffsets = SpUtil.getString('pages' + id)
            .split('-')
            .map((f) => int.parse(f))
            .toList();
      } else {
        r.pageOffsets = ReaderPageAgent.getPageOffsets(
            r.chapterContent, contentH, contentW, fontSize);
      }
    }
    print('white cache success');
    return r;
  }

  fillAllContent() {
    allContent = [];
    if (prePage != null) {
      allContent.addAll(chapterContent(prePage));
    }
    if (curPage != null) {
      allContent.addAll(chapterContent(curPage));
    }
    if (nextPage != null) {
      allContent.addAll(chapterContent(nextPage));
    }
    notifyListeners();
  }

  Widget readView() {
    return PageView.builder(
      controller: pageController,
      physics: AlwaysScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        return allContent[index];
      },
      //条目个数
      itemCount: (prePage == null ? 0 : prePage.pageOffsets.length) +
          (curPage == null ? 0 : curPage.pageOffsets.length) +
          (nextPage == null ? 0 : nextPage.pageOffsets.length),
      onPageChanged: (idx) => changeChapter(idx),
    );
  }

  justDown(start, end) async {
    for (var i = start; i < end;) {
      if (i == bookTag.chapters.length || i < 0) {
        break;
      }
      String id = bookTag.chapters[i].id;
      if (!SpUtil.haveKey(id)) {
        var url = Common.bookContentUrl + '/$id';
        Response response = await Util(null).http().get(url);
        String content = response.data['data']['content'].toString().trim();
        print('dark cache success');
        //缓存章节
        SpUtil.putString(id, content);
        //缓存章节分页
        SpUtil.putString(
            'pages' + id,
            ReaderPageAgent.getPageOffsets(
                    content, contentH, contentW, fontSize)
                .join('-'));
        bookTag.chapters[i].hasContent = 2;
      }
      i++;
    }
  }

  modifyFont() {
    if (!font) {
      font = !font;
    }
    bookTag.index = 0;
    SpUtil.remove('pages${bookTag.chapters[bookTag.cur].id}');
    intiPageContent(bookTag.cur, true);
//    notifyListeners();
  }

  toggleShowMenu() {
    showMenu = !showMenu;
    notifyListeners();
  }

  saveData() {
    SpUtil.putString(bookInfo.Id, jsonEncode(bookTag));
    SpUtil.putDouble('fontSize', fontSize);
    SpUtil.putInt('bgIdx', bgIdx);
  }

  void tapPage(BuildContext context, TapDownDetails details) {
    var wid = ScreenUtil.getScreenW(context);
    var hei = ScreenUtil.getScreenH(context);
    var space = wid / 3;
    var heig = hei / 3;
    var curWid = details.localPosition.dx;
    var curHei = details.localPosition.dy;
    if (curWid > 0 && curWid < space) {
      pageController.previousPage(
          duration: Duration(microseconds: 1), curve: Curves.ease);
    } else if (curWid > space && curWid < 2 * space && curHei < 2 * heig) {
      toggleShowMenu();
    } else {
      pageController.nextPage(
          duration: Duration(microseconds: 1), curve: Curves.ease);
    }
  }

  reCalcPages() {
    SpUtil.getKeys().forEach((f) {
      if (f.startsWith('pages')) {
        SpUtil.remove(f);
      }
    });
  }

  downloadAll() async {
    if (bookTag?.chapters?.isEmpty ?? 0 == 0) {
      await getChapters();
    }
    for (var chapter in bookTag.chapters) {
      chapter.hasContent = 2;
    }
    Toast.show("${bookInfo?.Name ?? ""}下载完成");
    saveData();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    saveData();
    super.dispose();
  }

  List<Widget> chapterContent(ReadPage r) {
    List<Widget> contents = [];
    for (var i = 0; i < r.pageOffsets.length; i++) {
      var content = r.stringAtPageIndex(i).trim();
      contents.add(
        GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (TapDownDetails details) {
              tapPage(context, details);
            },
            child: Container(
              child: Column(
                children: <Widget>[
                  SizedBox(height: ScreenUtil.getStatusBarH(context)),
                  Container(
                    height: 30,
                    padding: EdgeInsets.only(left: 3),
                    child: Text(
                      r.chapterName,
                      style: TextStyle(
                        fontSize: 16,
//                        color: Store.value<ColorModel>(context).dark
//                            ? Color.fromRGBO(225, 225, 225, 1)
//                            : Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Container(
                        padding: EdgeInsets.only(
                          right: 10,
                          left: 15,
                        ),
                        child: Text(
                          content,
                          style: TextStyle(
//                            color: Store.value<ColorModel>(context).dark
//                                ? Color.fromRGBO(225, 225, 225, 1)
//                                : Colors.black,
                            fontSize: fontSize / Screen.textScaleFactor,
                          ),
                        )),
                  ),
                  Container(
                    height: 30,
                    padding: EdgeInsets.only(right: 8),
                    child: Row(
                      children: <Widget>[
                        Expanded(child: Container()),
                        Text(
                          '第${i + 1}/${r.pageOffsets.length}页',
                          style: TextStyle(
                            fontSize: 13,
//                            color: Store.value<ColorModel>(context).dark
//                                ? Color.fromRGBO(225, 225, 225, 1)
//                                : Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
              width: double.infinity,
              height: double.infinity,
            )),
      );
    }
    return contents;
  }
}
