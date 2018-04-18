import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'globals.dart' as globals;

void main() => runApp(
    new MainApp()
  );

class MainApp extends StatefulWidget {

  // get last city set after exiting the app
  final lastCityIsSet = globals.activeCity; // boolean

  @override
  createState() => MainAppState(lastCityIsSet);
}

class MainAppState extends State<MainApp> {
  var hasActiveCity;
  // load active city from globals
  // if there is an active city show main screen,
  // if not show cityOverview

  MainAppState(var lastCityIsSet) {
    hasActiveCity = (lastCityIsSet != '');
  }

  // check if active city is unset
  String _getActiveCity() {
    String value;
    (hasActiveCity) ?  value = globals.activeCity : value = '';
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: (_getActiveCity() != '') ? new ActiveCity() : new CityOverview(),
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
      final _displayString = displayText.data; // plain text part of the Text-Widget
      final isActive = (_activeCity == _displayString);
      return new ListTile(
          title: displayText,
          trailing: new Icon(
            isActive ? Icons.star : Icons.star_border,
            color: isActive ? Colors.amber : null,
          ),
          onTap: () {
            setState(() {
              if (!isActive) {

                _activeCity = _displayString;
              } else {
                _activeCity = '';

              }
              // set active city for screen, but also for globals
              globals.activeCity = _activeCity;
            });
          }
      );
    }

    return new ListView.builder(
      padding: const EdgeInsets.all(16.0),

      itemBuilder: (context, i) {
        if (i.isOdd) return new Divider();

        final index = i ~/ 2;

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

  ActiveCityState() {
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

