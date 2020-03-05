import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purebook/model/ColorModel.dart';
import 'package:purebook/model/ReadModel.dart';
import 'package:purebook/model/SearchModel.dart';
import 'package:purebook/model/ShelfModel.dart';

class Store {
  static BuildContext context;
  static BuildContext widgetCtx;

  //  我们将会在main.dart中runAPP实例化init
  static init({context, child}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SearchModel()),
        ChangeNotifierProvider(create: (_) => ColorModel()),
        ChangeNotifierProvider(create: (_) => ShelfModel()),
        ChangeNotifierProvider(create: (_) => ReadModel()),
      ],
      child: child,
    );
  }

  //  通过Provider.value<T>(context)获取状态数据
  static T value<T>(context) {
    return Provider.of(context);
  }

  //  通过Consumer获取状态数据
  static Consumer connect<T>({builder, child}) {
    return Consumer<T>(builder: builder, child: child);
  }
}
