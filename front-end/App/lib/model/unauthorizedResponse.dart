import 'package:flutter/foundation.dart';
import 'package:hello_world/model/response_status.dart';

class UnauthorizedResponse {
  final ResponseStatus responseStatus;

  UnauthorizedResponse(this.responseStatus);

  factory UnauthorizedResponse.fromJson(dynamic json) {
    try {
      String response = json['error'] as String;
      switch(response) {
        case 'banned':
          return UnauthorizedResponse(ResponseStatus.BANNED);
        case 'expired':
          return UnauthorizedResponse(ResponseStatus.EXPIRED);
        case 'valid':
          throw Exception("This login token is valid.");
        default:
          throw Exception("Unauthorized response returned invalid result.");
      }
    } catch (e) {
      print(e);
      throw Exception(e);
    }
  }
}
