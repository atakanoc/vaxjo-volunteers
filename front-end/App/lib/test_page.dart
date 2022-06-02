import 'package:flutter/material.dart';
class TestPage extends StatelessWidget {
  const TestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Coming soon..."),
      ),
      body: const Center(
          child: Text("Test page."),
      ),
    );
  }
}
