import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'globals.dart' as globals;

void main() => runApp(
    new MainApp()
  );

class MainApp extends StatefulWidget {
  @override
  createState() => MainAppState();
}

class MainAppState extends State<MainApp> {
  var hasActiveCity;
  // load active city from globals
  // if there is an active city show main screen,
  // if not show cityOverview

  String _getActiveCity () {
    String value;

    (globals.activeCity != '') ?  value = globals.activeCity : value = '';

    return value;
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: (_getActiveCity() == '') ? new ActiveCity() : new CityOverview(),
    );
  }
}

class CityOverview extends StatefulWidget {
  @override
  createState() => CityOverviewState();

}

class CityOverviewState extends State<CityOverview> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        leading: new IconButton(icon: new Icon(Icons.arrow_back), onPressed: null),
        title: new Text('Saved City Overview'),
      ),
      // body: _buildSavedCitys,
    );
  }

  Widget _buildSavedCitys() {
    final _biggerFont = const TextStyle(fontSize: 18.0);

    var _activeCity;

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

        return _buildRow(
          new Text(
            _testCitys[index],
            style: _biggerFont
          )
        );
      }
    );
  }
}

class ActiveCity extends StatefulWidget {
  @override
  createState() => ActiveCityState();
}

class ActiveCityState extends State<ActiveCity> {
  final _suggestions = <WordPair>[];
  final _biggerFont = const TextStyle(fontSize: 18.0);

  var   _active;

  void _gotoOverview() {
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) {
          return new Scaffold (
            appBar: new AppBar(
                title: new Text('Saved City Overview'),
            ),
            body: _buildSuggestions(),
          );
        }
      ),
     );
  }

  Widget _buildSuggestions() {
    return new ListView.builder(
      padding: const EdgeInsets.all(16.0),

      itemBuilder: (context, i) {
        if (i.isOdd) return new Divider();

        final index = i ~/ 2;

        if (index >= _suggestions.length) {
          _suggestions.addAll(generateWordPairs().take(10));
        }

        return _buildRow(
          new Text(
            _suggestions[index].asPascalCase,
            style: _biggerFont
          )
        );
      }
    );
  }

  Widget _buildRow(Text displayText) {
    final _displayString = displayText.data; // plain text part of the Text-Widget
    final isActive = (_active == _displayString);
    return new ListTile(
      title: displayText,
      trailing: new Icon(
        isActive ? Icons.star : Icons.star_border,
        color: isActive ? Colors.amber : null,
      ),
      onTap: () {
        setState(() {
          if (!isActive) {
            _active = _displayString;
          } else _active = null;
        });
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold (
      appBar: new AppBar(
        title: new Text('Active City'),
        actions: <Widget>[
          new IconButton(icon: new Icon(Icons.list), onPressed: _gotoOverview)
        ]
      ),
        body: _active == null ? new Text('No Active City Set') : new Text(_active)
    );
  }
}

