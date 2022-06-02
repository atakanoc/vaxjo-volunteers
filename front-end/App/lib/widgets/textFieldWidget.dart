
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TextFieldWidget extends StatefulWidget {
  final int maxLines;
  final int maxChar;
  final String label;
  final String text;
  final ValueChanged<String> onChanged;
  final TextEditingController controller;
  const TextFieldWidget(
      {Key? key,
      this.maxLines = 1,
      required this.label,
      required this.text,
      required this.onChanged,
      required this.controller,
      required this.maxChar})
      : super(key: key);

  @override
  State<TextFieldWidget> createState() => _TextFieldWidgetState();
}

class _TextFieldWidgetState extends State<TextFieldWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.text = widget.text;
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
          const SizedBox(height: 8),
          TextFormField(
            validator: (text) {
              if (text == null || text.isEmpty) {
                return 'This field cannot be empty';
              }
              return null;
            },
            controller: widget.controller,
            decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16))),
            maxLines: widget.maxLines,
            maxLength: widget.maxChar,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
          )
        ],
      );
}
