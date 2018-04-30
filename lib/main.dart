import 'package:flutter/material.dart';

import 'globals.dart' as globals;
import 'settings.dart';
import 'cityOverview.dart';
import 'activeCity.dart';

// ===== ===== ===== =====
// TODO LIST
// ----- high priority -----
// ----- ----- ----- -----
//
// ----- low priority -----
// TODO: app logo cross with r-a-i-n lettering
// ----- ----- ----- -----
//
// ----- finally -----
// TODO: build apk
// ----- ----- ----- -----
// TODO LIST END
// ===== ===== ===== =====

void main() => runApp(
  new MainApp()
);

class MainApp extends StatefulWidget {
  // get last city set after exiting the app
  final lastCityIsSet = globals.activeCity; // boolean

  @override
  createState() => MainAppState();
}

class MainAppState extends State<MainApp> {

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      // directly goto cityOverview if no activeCity is set
      home: new ActiveCity(),
      // navigation routes for the screens
        routes: <String, WidgetBuilder> {
        '/activeCity':   (BuildContext context) => new ActiveCity(),
        '/cityOverview': (BuildContext context) => new CityOverview(),
        '/settingsView': (BuildContext context) => new SettingsView(),
      }
    );
  }
}