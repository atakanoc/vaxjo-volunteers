import 'package:flutter/material.dart';


class AppBarTitle extends StatelessWidget {

  static String? title;

  AppBarTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logowhite.png',
              scale: 6.5,
            ),
            Container(
              child: Text(title!),
              margin: const EdgeInsets.only(right: 75, left: 5),
            )
          ],
        );
  }
}