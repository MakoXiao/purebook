import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:purebook/common/common.dart';
import 'package:purebook/common/toast.dart';
import 'package:purebook/common/util.dart';
import 'package:purebook/entity/Book.dart';
import 'package:purebook/entity/BookInfo.dart';
import 'package:purebook/model/ColorModel.dart';
import 'package:purebook/model/ReadModel.dart';
import 'package:purebook/model/ShelfModel.dart';
import 'package:purebook/store/Store.dart';
import 'package:purebook/view/ChapterView.dart';
import 'package:purebook/view/myBottomSheet.dart';

import 'BookDetail.dart';

class ReadBook extends StatefulWidget {
  BookInfo _bookInfo;

  ReadBook(this._bookInfo);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _ReadBookState();
  }
}

class _ReadBookState extends State<ReadBook> with WidgetsBindingObserver {
  ReadModel readModel;

  //背景色数据
  List<List> bgs = [
    [246, 242, 234],
    [242, 233, 209],
    [231, 241, 231],
    [228, 239, 242],
    [242, 228, 228],
  ];
  final GlobalKey<ScaffoldState> _globalKey = new GlobalKey();

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    readModel.saveData();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    readModel.saveData();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    var widgetsBinding = WidgetsBinding.instance;
    widgetsBinding.addPostFrameCallback((callback) {
      readModel = Store.value<ReadModel>(context);
      readModel.bookInfo = this.widget._bookInfo;
      readModel.context = context;
      readModel.getBookRecord();
      if (SpUtil.haveKey('fontSize')) {
        readModel.fontSize = SpUtil.getDouble('fontSize');
      }
      if (SpUtil.haveKey('bgIdx')) {
        readModel.bgIdx = SpUtil.getInt('bgIdx');
      }
      readModel.contentH = ScreenUtil.getScreenH(context) -
          ScreenUtil.getStatusBarH(context) -
          60;
      readModel.contentW = ScreenUtil.getScreenW(context) - 25;
    });
  }

  Widget _createDialog(
      String _confirmContent, Function sureFunction, Function cancelFunction) {
    return AlertDialog(
      content: Text(_confirmContent),
      actions: <Widget>[
        FlatButton(onPressed: sureFunction, child: Text('确定')),
        FlatButton(onPressed: cancelFunction, child: Text('取消')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return WillPopScope(
      onWillPop: () async {
        if (!Store.value<ShelfModel>(context)
            .shelf
            .map((f) => f.Id)
            .toList()
            .contains(readModel.bookInfo.Id)) {
          var showDialog2 = await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    content: Text('是否加入本书'),
                    actions: <Widget>[
                      FlatButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Book book = new Book(
                                "",
                                "",
                                0,
                                readModel.bookInfo.Id,
                                readModel.bookInfo.Name,
                                readModel.bookInfo.Author,
                                readModel.bookInfo.Img,
                                readModel.bookInfo.LastChapterId,
                                readModel.bookInfo.LastChapter,
                                readModel.bookInfo.LastTime);
                            Store.value<ShelfModel>(context).modifyShelf(book);
                          },
                          child: Text('确定')),
                      FlatButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('取消')),
                    ],
                  ));
        }
        return true;
      },
      child: readModel != null
          ? Scaffold(
              key: _globalKey,
              backgroundColor: Store.value<ColorModel>(context).dark
                  ? Color.fromRGBO(102, 102, 102, 1)
                  : Color.fromRGBO(bgs[readModel.bgIdx][0],
                      bgs[readModel.bgIdx][1], bgs[readModel.bgIdx][2], 1),
              drawer: Drawer(
                child: ChapterView(),
              ),
              body: Stack(
                children: <Widget>[
                  readModel.readView(),
                  readModel.showMenu
                      ? Container(
                          color: Colors.transparent,
                          child: Column(
                            children: <Widget>[
                              Container(
                                child: AppBar(
                                  title: Text(
                                      '${readModel.bookTag.bookName ?? ""}'),
                                  centerTitle: true,
                                  leading: IconButton(
                                    icon: Icon(Icons.arrow_back),
                                    onPressed: () {
                                      readModel.toggleShowMenu();
                                    },
                                  ),
                                  elevation: 0,
                                  actions: <Widget>[
                                    IconButton(
                                      icon: Icon(Icons.info),
                                      onPressed: () async {
                                        String url = Common.detail +
                                            '/${readModel.bookInfo.Id}';
                                        Response future =
                                            await Util(context).http().get(url);
                                        var d = future.data['data'];
                                        BookInfo bookInfo =
                                            BookInfo.fromJson(d);

                                        Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(
                                                builder:
                                                    (BuildContext context) =>
                                                        BookDetail(bookInfo)));
                                      },
                                    )
                                  ],
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  child: Opacity(
                                    opacity: 1,
                                    child: Container(
                                      width: double.infinity,
                                    ),
                                  ),
                                  onTap: () {
                                    readModel.toggleShowMenu();

                                    if (readModel.font) {
                                      readModel.reCalcPages();
                                    }
                                  },
                                ),
                              ),
                              Container(
                                color: Theme.of(context).primaryColor,
                                height: 120,
                                width: double.infinity,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        GestureDetector(
                                          child: Container(
                                            child: Icon(Icons.arrow_back_ios),
                                            width: 70,
                                          ),
                                          onTap: () {
                                            readModel.bookTag.cur -= 1;
                                            readModel.intiPageContent(
                                                readModel.bookTag.cur, true);
                                          },
                                        ),
                                        Expanded(
                                          child: Container(
                                            child: Slider(
                                              activeColor: Colors.black38,
                                              inactiveColor: Colors.white30,
                                              value: readModel.value,
                                              max: (readModel.bookTag.chapters
                                                          .length -
                                                      1)
                                                  .toDouble(),
                                              min: 0.0,
                                              onChanged: (newValue) {
                                                int temp = newValue.round();
                                                readModel.bookTag.cur = temp;
                                                readModel.value =
                                                    temp.toDouble();
                                                readModel.intiPageContent(
                                                    readModel.bookTag.cur,
                                                    true);
                                              },
                                              label:
                                                  '${readModel.bookTag.chapters[readModel.bookTag.cur].name} ',
                                              semanticFormatterCallback:
                                                  (newValue) {
                                                return '${newValue.round()} dollars';
                                              },
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          child: Container(
                                            child:
                                                Icon(Icons.arrow_forward_ios),
                                            width: 70,
                                          ),
                                          onTap: () {
                                            readModel.bookTag.cur += 1;
                                            readModel.intiPageContent(
                                                readModel.bookTag.cur, true);
                                          },
                                        ),
                                      ],
                                    ),
                                    buildBottomMenus()
                                  ],
                                ),
                              )
                            ],
                          ),
                        )
                      : Container()
                ],
              ))
          : Scaffold(),
    );
  }

  buildBottomMenus() {
    return Store.connect<ColorModel>(
        builder: (BuildContext context, ColorModel data, chile) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                buildBottomItem('目录', Icons.menu),
                GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: ScreenUtil.getScreenW(context) / 4,
                      padding: EdgeInsets.symmetric(vertical: 7),
                      child: Column(
                        children: <Widget>[
                          ImageIcon(data.dark
                              ? AssetImage("images/moon.png")
                              : AssetImage("images/sun.png")),
                          SizedBox(height: 5),
                          Text(data.dark ? '夜间' : '日间',
                              style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    onTap: () {
                      Store.value<ColorModel>(context).switchModel();
                      setState(() {});
                      readModel.toggleShowMenu();
                    }),
                buildBottomItem('缓存', Icons.cloud_download),
                buildBottomItem('设置', Icons.settings),
              ],
            ));
  }

  buildBottomItem(String title, IconData iconData) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: ScreenUtil.getScreenW(context) / 4,
        padding: EdgeInsets.symmetric(vertical: 7),
        child: Column(
          children: <Widget>[
            Icon(iconData),
            SizedBox(height: 5),
            Text(title, style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      onTap: () {
        print(title.toString());
        switch (title) {
          case '目录':
            {
              _globalKey.currentState.openDrawer();
              readModel.toggleShowMenu();
            }
            break;
          case '缓存':
            {
              Toast.show('开始下载...');
              readModel.downloadAll();
            }
            break;
          case '设置':
            {
              myshowModalBottomSheet(
                  context: context,
                  builder: (BuildContext bc) {
                    return StatefulBuilder(
                        builder: (context, state) => buildSetting(state));
                  });
            }
            break;
        }
      },
    );
  }

  buildSetting(state) {
    return Container(
      height: 150,
      child: Padding(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('亮度'),
                Expanded(
                  child: Container(
                    child: Slider(
                      activeColor: Colors.black38,
                      inactiveColor: Colors.white30,
                      value: 50,
                      max: 100,
                      min: 0.0,
                      onChanged: (newValue) {},
                    ),
                  ),
                ),
                Container(
                  width: 130,
                  child: Row(
                    children: <Widget>[
                      Text('跟随系统'),
                      Checkbox(
                        value: false,
                        activeColor: Colors.blue,
                        onChanged: (bool val) {},
                      )
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Text('字号'),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Container(
                    child: FlatButton(
                      color: Colors.black38,
                      onPressed: () {
                        readModel.fontSize -= 1.0;
                        readModel.modifyFont();
                      },
                      child: ImageIcon(
                        AssetImage("images/fontsmall.png"),
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(20.0))),
                    ),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Container(
                    child: FlatButton(
                      color: Colors.black38,
                      onPressed: () {
                        readModel.fontSize += 1.0;
                        readModel.modifyFont();
                      },
                      child: ImageIcon(
                        AssetImage("images/fontbig.png"),
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(20.0))),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Text('背景'),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: readThemes(state),
                  ),
                )
              ],
            ),
          ],
        ),
        padding: EdgeInsets.only(left: 10, right: 10),
      ),
      color: Store.value<ColorModel>(context).dark
          ? Color.fromRGBO(38, 38, 38, 1)
          : Color.fromRGBO(bgs[readModel.bgIdx][0], bgs[readModel.bgIdx][1],
              bgs[readModel.bgIdx][2], 1),
    );
  }

  List<Widget> readThemes(state) {
    List<Widget> wds = [];
    for (var i = 0; i < bgs.length; i++) {
      var f = bgs[i];
      wds.add(RawMaterialButton(
        onPressed: () {
          readModel.switchBgColor(i);
          state(() {});
        },
        constraints: BoxConstraints(minWidth: 60.0, minHeight: 50.0),
        child: Container(
          margin: EdgeInsets.only(top: 5.0, bottom: 5.0),
          width: 40.0,
          height: 40.0,
          decoration: BoxDecoration(
              color: Color.fromRGBO(f[0], f[1], f[2], 1),
              borderRadius: BorderRadius.all(Radius.circular(25.0)),
              border: readModel.bgIdx == i
                  ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                  : Border.all(color: Colors.white30)),
        ),
      ));
    }
    wds.add(SizedBox(
      height: 8,
    ));
    return wds;
  }
}
