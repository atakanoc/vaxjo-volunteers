import 'package:flutter/foundation.dart';

/// This is used for submitting a post to backend and to serialize it correctly.
class UserPost {
  final String title;
  final String description;
  final String category;

  UserPost(this.title, this.description, this.category);

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'category': category,
  };
}
