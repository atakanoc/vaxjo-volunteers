# Readme of the frontend

## Prerequisites
1. [Visual Studio Code](https://code.visualstudio.com/download) - IDE used to build and run the application. Android Studio can be used for the same purposes (Android SDK that is by default is installed with Android Studio is mandatory and is mentioned in the next step), but VS Code might be a more convenient option for developing an application in a long run.
2. [Flutter framework](https://docs.flutter.dev/get-started/install) - An open-source UI software development kit used for mobile development. We recommend Flutter version >= 2.10.5. **When installing the Flutter framework, please make sure to follow the detailed steps in the link, though Web Setup can be completely ignored**. 

    <p>IMPORTANT IN THE ABOVE LINK:</p>
  - [Android setup, Android Studio installation](https://docs.flutter.dev/get-started/install/macos#install-android-studio). Android Studio Setup Wizard  will install the Android SDK, Android SDK Command-line and Build-Tools in order to be able to build Flutter application for Android (the default emulators should also be available after this step).

  - [iOS setup, Xcode](https://docs.flutter.dev/get-started/install/macos#ios-setup). Please note, that it is completely acceptable to ignore Xcode installation for the testing purposes, because the prototype GUI is the same for Android and iOS platforms. 

  - [Running flutter doctor command](https://docs.flutter.dev/get-started/install/macos#run-flutter-doctor) is very useful to find out what dependencies and licences are still needed for the complete Flutter setup.

3. `Flutter plugin for VS code` - Install via the VS Code Extensions interface (icon in the left side panel of VS Code) by searching for `Flutter` or [from the VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter). This extension will automatically install the `Dart plugin` (Dart is the programming language that is used by the Flutter framework).
4. The backend part of our project must already be deployed and available either locally or via LAN.


## Building and launching the frontend
1. Unzip the archive with the frontend source code and open the **App** folder  with the help of VS Code.
2. Make sure that VS Code and Flutter are properly working (no errors are reported in the IDE), and either a real mobile device (via USB) or emulator (Android or iOS) are selected. To select the available connected mobile device or the emulator, use the VS Code Command Palette (⇧⌘P / ⇧^P , depending on the OS) and search for `Flutter:Select Device`.
3. If the physical mobile device is connected via USB and used for testing, make sure that the Developer Mode and USB debugging are enabled (example for the Android platform https://developer.android.com/studio/debug/dev-options). Only after this it will be visible for the selection in the above step.
4. Check the IP address and port in the `App/lib/main.dart` (line 19) to be the same as the IP address and port of the backend (for example `Utils.IP = '192.168.0.101:7070'`);
5. Run the program from the VS Code menu panel `Run -> Run without Debugging` to start application on emulator or actual smartphone. At the same time, you can observe launching lib/main.dart in debug mode and Flutter application build in the debug console of the VS Code. 

