import 'package:flutter/foundation.dart';

class LoginResponse {
  final String loginToken;

  LoginResponse(this.loginToken);

  factory LoginResponse.fromJson(dynamic json) {
    try {
      final loginToken = json['token'] as String;

      return LoginResponse(loginToken);
    } catch (e) {
      print(e);
      throw Exception(e);
    }
  }
}
