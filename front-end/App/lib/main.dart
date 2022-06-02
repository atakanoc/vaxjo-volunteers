import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import './model/heartbeatResponse.dart';
import './pages/settings.dart';
import './test_page.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import './utils.dart';
import './widgets/appBarTitle.dart';
import './pages/hompage.dart';
import './pages/loginpage.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  String? token = await Utils.getLoginToken();

  Utils.IP = '192.168.1.7:7070';
  AppBarTitle.title = 'Växjö Volunteers';

  if (token.isNotEmpty) {
    final uri = Uri.http(Utils.IP, '/heartbeat');

    final postResponse = await http.post(uri, headers: {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: token
    });

    if (postResponse.statusCode != 200) {
      Utils.reasonToken = Utils.checkAuthError(postResponse);
      Utils.clearLoginToken();
    } else {
      // heartbeat returns it saving from calling backend again
      Utils.currentUser = HeartbeatResponse.fromJson(jsonDecode(postResponse.body));
    }
  }

  MyApp.themeNotifier.value =
      await Utils.getTheme() ? ThemeMode.dark : ThemeMode.light;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  // TODO: Make initial theme load from disk.
  static ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.light);

  const MyApp({Key? key}) : super(key: key);
  //static const String appName = "Växjö Volunteers";

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    String routeToUse;
    if (Utils.token.isEmpty) {
      routeToUse = '/login';
    } else {
      if (Utils.reasonToken != null) {
        routeToUse = '/login';
      } else {
        routeToUse = '/home';
      }
    }
    FlutterNativeSplash.remove();
    return ValueListenableBuilder(
        // Basically this will rebuild the whole app
        valueListenable: themeNotifier, // when the theme is changed.
        builder: (_, ThemeMode themeMode, __) => MaterialApp(
                debugShowCheckedModeBanner: false,
                title: AppBarTitle.title!,
                theme: ThemeData(
                  primarySwatch: Colors.teal,
                ),
                darkTheme: ThemeData.dark(),
                themeMode: themeMode,
                initialRoute: routeToUse,
                routes: {
                  // Home page that is login
                  '/login': ((context) =>
                      const LoginPage()),
                  // When navigating to the "/" route, build the FirstScreen widget.
                  '/home': (context) =>
                      const MyHomePage(),
                  '/settings': (context) => const SettingsPage(),
                  '/test': (context) => const TestPage(),
                }));
  }
}
