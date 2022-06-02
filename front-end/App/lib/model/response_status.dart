// ignore_for_file: constant_identifier_names

enum ResponseStatus {
  OK,
  SERVERERR,
  UNAUTHORIZED,
  NORESPONSEAUTH,
  AUTHFAIL,
  BANNED,
  EXPIRED,
  INVALID,
  NOTFOUND,
  INAPPROPRIATE,
}

extension ResponseStatusExtension on ResponseStatus {
  String get name {
    switch (this) {
      case ResponseStatus.OK:
        return 'Successful operation';
      case ResponseStatus.SERVERERR:
        return '500 Internal Server Error';
      case ResponseStatus.UNAUTHORIZED:
        return '401 Unauthorized';
      case ResponseStatus.NORESPONSEAUTH:
        return 'OAuth process failed.';
      case ResponseStatus.AUTHFAIL:
        return 'Backend auth failed.';
      case ResponseStatus.BANNED:
        return 'You are permanently banned.';
      case ResponseStatus.EXPIRED:
        return 'Token expired, please re-login.';
      case ResponseStatus.NOTFOUND:
        return 'Record is not found.';
      case ResponseStatus.INAPPROPRIATE:
        return 'Inappropriate post content';
      default:
        return '';
    }
  }
}
