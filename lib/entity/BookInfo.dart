import 'package:json_annotation/json_annotation.dart';

import 'Book.dart';
import 'BookVotec.dart';

part 'BookInfo.g.dart';

@JsonSerializable()
class BookInfo {
  String Author;
  String BookStatus;
  BookVotec BookVote;
  String CId;
  String CName;
  String Id;
  String Name = "";
  String Img;
  String Desc;
  String LastChapterId;
  String LastChapter;
  String FirstChapterId;
  String LastTime;
  List<Book> SameAuthorBooks;

  factory BookInfo.fromJson(Map<String, dynamic> json) =>
      _$BookInfoFromJson(json);

  Map<String, dynamic> toJson() => _$BookInfoToJson(this);

  BookInfo.id(this.Id, this.Name, this.Img);

  BookInfo.name(this.CId, this.Name);

  BookInfo(
      this.Author,
      this.BookStatus,
      this.BookVote,
      this.CId,
      this.CName,
      this.Id,
      this.Name,
      this.Img,
      this.Desc,
      this.LastChapterId,
      this.LastChapter,
      this.FirstChapterId,
      this.LastTime,
      this.SameAuthorBooks);
}
