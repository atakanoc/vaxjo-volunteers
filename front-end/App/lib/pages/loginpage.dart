import 'dart:convert';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import '../widgets/alertdialog.dart';
import '../model/loginResponse.dart';
import '../model/response_status.dart';
import 'package:hello_world/model/unauthorizedResponse.dart';
import '../utils.dart';
import '../widgets/appBarTitle.dart';
import 'package:http/http.dart' as http;

import 'hompage.dart';
import '../model/heartbeatResponse.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

FlutterAppAuth appAuth = const FlutterAppAuth();

class _LoginPageState extends State<LoginPage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  String clientID =
      "111651285661-1ferihuejo6520tosf9h9iudkf6qoj8q.apps.googleusercontent.com";
  String backendURL = "se.lnu.vaxjovolunteers:/oauthredirect";

  // do not change this below
  String discoveryURL =
      "https://accounts.google.com/.well-known/openid-configuration";

  Future<AuthorizationTokenResponse?> _handleSignIn() async {
    try {
      final AuthorizationTokenResponse? result =
          await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(clientID, backendURL,
            discoveryUrl: discoveryURL,
            scopes: [
              "https://www.googleapis.com/auth/userinfo.profile",
              "openid"
            ],
            allowInsecureConnections: true),
      );
      return result;
    } catch (e) {
      return null;
    }
  }

  void _handleLogin(BuildContext context) async {
    AuthorizationTokenResponse? response = await _handleSignIn();
    if (response == null) {
      setState(() {
        AlertDialogPop alertDialog =
            AlertDialogPop('Error', ResponseStatus.NORESPONSEAUTH.name);
        showDialog(context: context, builder: alertDialog.build);
      });
    } else {
      final queryParameters = {
        'access_token': response.accessToken,
        'refresh_token': response.refreshToken,
        'access_token_lifetime':
            response.accessTokenExpirationDateTime.toString()
      };

      final uri = Uri.http(Utils.IP, '/login', queryParameters);

      final postResponse = await http.post(uri, headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
      });

      if (postResponse.statusCode == 200) {
        // store token
        // navigate user to home

        LoginResponse loginResponse =
            LoginResponse.fromJson(jsonDecode(postResponse.body));

        Utils.setLoginToken(loginResponse.loginToken);
        debugPrint("Token is + ${loginResponse.loginToken}");

        // Assign current user on the initial app login
        if (Utils.currentUser == null) {
          final uri = Uri.http(Utils.IP, '/heartbeat');
          final response = await http.post(uri, headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.authorizationHeader: loginResponse.loginToken
          });
          Utils.currentUser =
              HeartbeatResponse.fromJson(jsonDecode(response.body));
        }
        //////////////////////////////////////////////////////////////
        Navigator.pushReplacement<void, void>(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) => const MyHomePage(),
          ),
        );
      } else {
        if (postResponse.statusCode == 401) {
          print("Reached 401 for login page");
          UnauthorizedResponse unauthorizedResponse =
              Utils.checkAuthError(postResponse);
          Utils.showAuthErrorDialog(unauthorizedResponse, context, false);
        } else {
          setState(() {
            AlertDialogPop alertDialog =
                AlertDialogPop('Error', ResponseStatus.AUTHFAIL.name);
            showDialog(context: context, builder: alertDialog.build);
          });
        }
      }
      // code validated on backend
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Utils.reasonToken != null) {
      Utils.logOut(context, Utils.reasonToken!, scheduler: true);
    }
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: AppBarTitle(),
      ),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            fixedSize: const Size(200, 200),
            shape: const CircleBorder(),
          ),
          onPressed: () => _handleLogin(context),
          child: const Text('Login with Google'),
        ),
      ),
    );
  }
}
