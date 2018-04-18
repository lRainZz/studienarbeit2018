import 'package:flutter/material.dart';
import 'globals.dart' as globals;

// ===== ===== ===== =====
// TODO LIST
// ----- high prio -----
// TODO: add input field for city's
// TODO: add fitting weather API
// TODO: load weather data for saved city's / give a hint when the city couldn't be found
// TODO: display data of active city on active city screen
// ----- ----- ----- -----
//
// ----- low prio -----
// TODO: live search of available citys via the API (if offered)
// TODO: nice UI for active city screen (no AppBar, nice background, nice icons etc.)
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
  var hasActiveCity;
  // load active city from globals
  // if there is an active city show main screen,
  // if not show cityOverview

  // constructor
  MainAppState() {
    // reading state from last app start
    hasActiveCity = (globals.activeCity != '');
  }

  // check if active city is set
  String _getActiveCity() {
    String value;
    (hasActiveCity) ?  value = globals.activeCity : value = '';
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      // directly goto cityOverview if no activeCity is set
      home: (_getActiveCity() != '') ? new ActiveCity() : new CityOverview(),
      // navigation routes for the screens
        routes: <String, WidgetBuilder> {
        '/activeCity':   (BuildContext context) => new ActiveCity(),
        '/cityOverview': (BuildContext context) => new CityOverview()
      }
    );
  }
}

class CityOverview extends StatefulWidget {
  @override
  createState() => CityOverviewState();

}

class CityOverviewState extends State<CityOverview> {
  var _activeCity;

  // constructor
  CityOverviewState () {
    // read active city
    _activeCity = globals.activeCity;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        // hand over function only like this: '() => funcName()'
        // with only 'funcName()' the function is called immediately after the builder is finished!
        // with only 'funcName' the function is not called at all!
        leading: new IconButton(icon: new Icon(Icons.arrow_back), onPressed: () => _goToActiveCity()),
        title: new Text('Saved City Overview'),
      ),
      body: _buildSavedCitys(),
    );
  }

  _goToActiveCity () {
    // pushNamed would generate a route which can be navigated back
    // with pushReplacementNamed you basically switch between screens
    Navigator.of(context).pushReplacementNamed('/activeCity');
  }

  Widget _buildSavedCitys() {
    final _biggerFont = const TextStyle(fontSize: 18.0);

    // load saved citys from db
    // simulated:
    final _testCitys = <String>[];
    _testCitys.add('Freiburg');
    _testCitys.add('Berlin');
    _testCitys.add('Dortmund');

    Widget _buildRow(Text displayText) {
      // comparison with raw string not the object!
      final isActive = (_activeCity == displayText.data);

      // build single row of list as tile
      return new ListTile(
          title: displayText,
          trailing: new Icon(
            isActive ? Icons.star : Icons.star_border,
            color: isActive ? Colors.amber : null,
          ),
          // set state, so that the icon will be updated
          onTap: () {
            setState(() {
              if (!isActive) {
                 // write raw string into activeCity
                _activeCity = displayText.data;
              } else {
                _activeCity = '';
              }
              // set active city for globals, no matter the outcome
              globals.activeCity = _activeCity;
            });
          }
      );
    }

    return new ListView.builder(
      // set padding for all tiles
      padding: const EdgeInsets.all(16.0),

      itemBuilder: (context, i) {
        // set every other row as divider
        if (i.isOdd) return new Divider();

        // break down index for the actual tiles
        final index = i ~/ 2;

        // add tiles
        if (index < _testCitys.length) {
          return _buildRow(
              new Text(
                  _testCitys[index],
                  style: _biggerFont
              )
          );
        }
      }
    );
  }
}

class ActiveCity extends StatefulWidget {
  @override
  createState() => ActiveCityState();
}

class ActiveCityState extends State<ActiveCity> {
  var _activeCity;

  // constructor
  ActiveCityState() {
    // load active city
    _activeCity = globals.activeCity;
  }

  _goToCityOverview() {
    // pushNamed would generate a route which can be navigated back
    // with pushReplacementNamed you basically switch between screens
    Navigator.of(context).pushReplacementNamed('/cityOverview');
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold (
      appBar: new AppBar(
        title: new Text('Active City'),
        actions: <Widget>[
          // hand over function only like this: '() => funcName()'
          // with only 'funcName()' the function is called immediately after the builder is finished!
          // with only 'funcName' the function is not called at all!
          new IconButton(icon: new Icon(Icons.list), onPressed: () => _goToCityOverview()),
        ]
      ),
        body: _activeCity == '' ? new Text('No Active City Set') : new Text(_activeCity)
    );
  }
}

