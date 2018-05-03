import 'package:flutter/material.dart';

import 'globals.dart' as globals;
import 'settings.dart';
import 'cityOverview.dart';
import 'activeCity.dart';
import 'dbConnection.dart';

// ===== ===== =====
// TODO: SQLite database
// ===== ===== =====

void main() => runApp(new MainApp());

class MainApp extends StatefulWidget {
  @override
  createState() => MainAppState();
}

class MainAppState extends State<MainApp> {

  MainAppState() {
    globals.con = new DBConnection();
  }

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