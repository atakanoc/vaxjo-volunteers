import 'package:flutter/material.dart';

class AlertDialogPop extends StatelessWidget {
  String message;
  String header;

  AlertDialogPop(this.header, this.message);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0))),
      title: Text(header),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(message),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(
              textStyle: TextStyle(color: Theme.of(context).primaryColor)),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
