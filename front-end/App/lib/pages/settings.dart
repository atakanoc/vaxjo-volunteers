import 'package:flutter/material.dart';
import '../main.dart';
import '../utils.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Settings")
      ),
      body: Center(
          child: _buildSettingsList()
      ),
    );
  }

  Widget _buildSettingsList() {
    List<Widget> tiles = [_buildDarkModeTile(), _buildNotificationsTile()];
    return ListView.separated(
      itemBuilder: (BuildContext context, int index) {
        return tiles[index];
      },
      itemCount: tiles.length,
      separatorBuilder: (BuildContext context, int index) => const Divider(),
    );
  }

  Widget _buildDarkModeSwitch() {
    // TODO: Make theme save to disk upon change.
    return Switch(
      value: MyApp.themeNotifier.value == ThemeMode.dark ? true : false,
      onChanged: (value) {
        setState(() {
          if (value) {  // If toggle is on, then it's dark mode
            MyApp.themeNotifier.value = ThemeMode.dark;
          } else {
            MyApp.themeNotifier.value = ThemeMode.light;
          }
          Utils.setDarkMode(value);

        });
      }
    );
  }

  Widget _buildDarkModeTile() {
    return ListTile(
      title: const Text("Dark mode"),
      trailing: _buildDarkModeSwitch(),
    );
  }

  // TODO: Make this go to a valid page for notifications.
  Widget _buildNotificationsTile() {
    return ListTile(
      title: const Text("Notifications"),
      trailing: const Icon(Icons.arrow_right),
      onTap: () => Navigator.pushNamed(context, '/test'),
    );
  }
}
