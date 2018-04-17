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
      // use routing for navigation, see bookmark !!!
      home: (_getActiveCity() != '') ? new ActiveCity() : new CityOverview(),
    );
  }
}

class CityOverview extends StatefulWidget {
  @override
  createState() => CityOverviewState();

}

class CityOverviewState extends State<CityOverview> {
  var _activeCity;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        leading: new IconButton(icon: new Icon(Icons.arrow_back), onPressed: _goToActiveCity()),
        title: new Text('Saved City Overview'),
      ),
      body: _buildSavedCitys(),
    );
  }

  _goToActiveCity () {
    globals.activeCity = _activeCity;
  }

  Widget _buildSavedCitys() {
    final _biggerFont = const TextStyle(fontSize: 18.0);



    // load saved citys from db
    // simualated:
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
                globals.activeCity = _displayString;
              } else _activeCity = null;
            });
            // save active city to db
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
  final _biggerFont = const TextStyle(fontSize: 18.0);

  var   _active;

  @override
  Widget build(BuildContext context) {
    return new Scaffold (
      appBar: new AppBar(
        title: new Text('Active City'),
        actions: <Widget>[
          new IconButton(icon: new Icon(Icons.list), onPressed: null),
        ]
      ),
        body: _active == null ? new Text('No Active City Set') : new Text(_active)
    );
  }
}

