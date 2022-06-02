import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:hello_world/widgets/alertdialog.dart';
import 'package:hello_world/main.dart';
import 'package:hello_world/model/response_status.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/loginpage.dart';
import 'model/heartbeatResponse.dart';
import 'model/unauthorizedResponse.dart';

class Utils {
  // # TODO: Make a universal request call
  static String IP = "";
  static String token = "";
  static UnauthorizedResponse? reasonToken;
  static HeartbeatResponse? currentUser;

  static Future<String> getLoginToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? maybeToken = prefs.getString("token");
    if (maybeToken != null) {
      token = maybeToken;
    }
    return token;
  }

  static void setLoginToken(String newToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", newToken);
    token = newToken;
  }

  static void clearLoginToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    token = "";
  }

  static void handleInvalidAuth(BuildContext buildContext, Response response) {
    UnauthorizedResponse unauthorizedResponse = checkAuthError(response);
    logOut(buildContext, unauthorizedResponse);
  }

  static UnauthorizedResponse checkAuthError(Response response) {
    UnauthorizedResponse unauthorizedResponse =
        UnauthorizedResponse.fromJson(jsonDecode(response.body));
    return unauthorizedResponse;
  }

  /// # TODO: Add this at every page
  /// Use this method when you know we received 401 error.
  /// Fetch the error to pass through with checkAuthError method.
  static void logOut(
      BuildContext context, UnauthorizedResponse unauthorizedResponse,
      {bool scheduler = true}) async {
    if (Utils.token.isNotEmpty) {
      clearLoginToken();
    }

    showAuthErrorDialog(unauthorizedResponse, context, scheduler);
    if (ModalRoute.of(context)?.settings.name != "/login") {
      await Navigator.pushReplacement<void, void>(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) =>
              const LoginPage(),
        ),
      );
    }
  }

  /// Only pass scheduler true if you know it has a schedulerBinding.
  static void showAuthErrorDialog(UnauthorizedResponse unauthorizedResponse,
      BuildContext buildContext, bool scheduler) {
    switch (unauthorizedResponse.responseStatus) {
      case ResponseStatus.EXPIRED:
        AlertDialogPop alertDialog =
            AlertDialogPop("Error", ResponseStatus.EXPIRED.name);

        if (scheduler) {
          SchedulerBinding.instance!.addPostFrameCallback((_) {
            showDialog(context: buildContext, builder: alertDialog.build);
          });
        } else {
          showDialog(context: buildContext, builder: alertDialog.build);
        }

        break;
      case ResponseStatus.BANNED:
        AlertDialogPop alertDialog =
            AlertDialogPop("Error", ResponseStatus.BANNED.name);

        if (scheduler) {
          SchedulerBinding.instance!.addPostFrameCallback((_) {
            showDialog(context: buildContext, builder: alertDialog.build);
          });
        } else {
          showDialog(context: buildContext, builder: alertDialog.build);
        }

        break;
      default:
        throw Exception("This should not be reached, invalid input.");
    }
  }

  static void setDarkMode(bool set) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool("darkMode", set);
  }

  static Future<bool> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("darkMode") ?? false;
  }

  static void showOperationStatus(
      String header, int statusCode, BuildContext context) {
    String status = 'Undefined';
    switch (statusCode) {
      case 200:
        status = ResponseStatus.OK.name;
        break;
      case 500:
        status = ResponseStatus.SERVERERR.name;
        break;
      case 401:
        status = ResponseStatus.UNAUTHORIZED.name;
        break;
      case 404:
        status = ResponseStatus.NOTFOUND.name;
        break;
      case 400:
        status = ResponseStatus.INAPPROPRIATE.name;
        break;
    }
    AlertDialogPop dialog = AlertDialogPop(header, status);
    showDialog(context: context, builder: dialog.build);
  }
}
