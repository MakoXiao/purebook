import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:purebook/common/common.dart';
import 'package:purebook/common/util.dart';
import 'package:purebook/model/ColorModel.dart';
import 'package:purebook/store/Store.dart';

class ForgetPass extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return new _ForgetPassState();
  }
}

class _ForgetPassState extends State<ForgetPass> {
  String account;
  String newpwd;
  String email;
  String repetpwd;
  var _scaffoldkey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return  Theme(child: Material(child: Container(
      alignment: Alignment.center,
      child: new ListView(
        shrinkWrap: true,
        padding: EdgeInsets.only(left: 24.0, right: 24.0),
        children: <Widget>[
          TextFormField(
            keyboardType: TextInputType.phone,
            autofocus: false,
            decoration: InputDecoration(
              hintText: '账号',
              contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
//                border: OutlineInputBorder(
//                    borderRadius: BorderRadius.circular(32.0)),
            ),
            onChanged: (String value) {
              this.account = value;
            },
          ),
          SizedBox(height: 8.0),
          TextFormField(
            autofocus: false,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: '邮箱',
              contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
//                border: OutlineInputBorder(
//                    borderRadius: BorderRadius.circular(32.0)),
            ),
            onChanged: (String value) {
              email = value;
            },
          ),
          SizedBox(height: 8.0),
          TextFormField(
            autofocus: false,
            obscureText: true,
            decoration: InputDecoration(
              hintText: '输入新密码',
              contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
//                border: OutlineInputBorder(
//                    borderRadius: BorderRadius.circular(32.0)),
            ),
            onChanged: (String value) {
              newpwd = value;
            },
          ),
          SizedBox(height: 8.0),
          TextFormField(
            obscureText: true,
            autofocus: false,
            decoration: InputDecoration(
              hintText: '重复新密码',
              contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
//                border: OutlineInputBorder(
//                    borderRadius: BorderRadius.circular(32.0)),
            ),
            onChanged: (String value) {
              repetpwd = value;
            },
          ),
          SizedBox(height: 8.0),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: RaisedButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              onPressed: () {
                register();
              },
              padding: EdgeInsets.all(12),
              color: Colors.grey,
              child: Text('修改密码', style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    ),),data: Store.value<ColorModel>(context).theme,);
  }

  register() async {
    if (newpwd != repetpwd) {
      _scaffoldkey.currentState
          .showSnackBar(new SnackBar(content: new Text('两次密码不一致,请修改')));
      return;
    }
    if (newpwd.isNotEmpty &&
        repetpwd.isNotEmpty &&
        account.isNotEmpty &&
        email.isNotEmpty) {
      Response response = await Util(context).http().patch(Common.modifypassword,
          data: {"name": account, "password": newpwd, "email": email});

      var data = response.data;
      _scaffoldkey.currentState
          .showSnackBar(new SnackBar(content:  Text(data['msg'])));
    } else {
      _scaffoldkey.currentState
          .showSnackBar(new SnackBar(content:  Text('检查输入项不可为空')));
    }
  }
}
