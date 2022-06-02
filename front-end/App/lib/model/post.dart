import 'package:flutter/foundation.dart';

class Post {
  final int postID;
  final String authorID;
  final String authorName;
  final String title;
  final String description;
  final DateTime date;
  final String category;
  final String? status;
  final String? modComment;

  Post(this.postID, this.authorID, this.authorName, this.title,
      this.description, this.date, this.category, this.status, this.modComment);

  factory Post.fromJson(dynamic json) {
    try {
      final postID = json['postID'] as int;
      final authorID = json['author_id'] as String;
      final authorName = json['author_name'] as String;
      final title = json['title'] as String;
      final description = json['description'] as String;
      final date = DateTime.parse(json['date']).toLocal();
      final category = json['category'] as String;
      final status = json['status'] as String;
      final modComment = json['modComment'] as String?;

      return Post(postID, authorID, authorName, title, description, date,
          category, status, modComment);
    } catch (e) {
      print(e);
      throw Exception(e);
    }
  }

  Map<String, dynamic> toJson() => {
        'postID': postID,
        'author_id': authorID,
        'author_name': authorName,
        'title': title,
        'description': description,
        'date': date.toUtc().toIso8601String(),
        'category': category,
        'status': status,
        'modComment': modComment
      };
}
