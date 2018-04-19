import 'package:flutter/material.dart';
import 'globals.dart' as globals;
import 'helper.dart';

import 'package:flutter/rendering.dart';

// ===== ===== ===== =====
// TODO LIST
// ----- high priority -----
// TODO: add fitting weather API
// TODO: add class of 'city' with name an zip code
// TODO: load weather data for saved city's / give a hint when the city couldn't be found
// TODO: display data of active city on active city screen
// ----- ----- ----- -----
//
// ----- low priority -----
// TODO: live search of available citys via the API (if offered)
// TODO: nice UI for active city screen (no AppBar, nice background, nice icons etc.)
// TODO: change navigation so that screens go from left to right and v.v. instead of bottom up
// TODO: split classes into different files
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

  // constructor
  MainAppState() {
    // reading state from last app start
    hasActiveCity = (globals.activeCity != null);
  }

  // check if active city is set
  CityData _getActiveCity() {
    CityData value;
    (hasActiveCity) ?  value = globals.activeCity : value = null;
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      // directly goto cityOverview if no activeCity is set
      home: (_getActiveCity() != null) ? new ActiveCity() : new CityOverview(),
      // navigation routes for the screens
        routes: <String, WidgetBuilder> {
        '/activeCity':   (BuildContext context) => new ActiveCity(),
        '/cityOverview': (BuildContext context) => new CityOverview(),
      }
    );
  }
}

class CityOverview extends StatefulWidget {
  @override
  createState() => CityOverviewState();

}

class CityOverviewState extends State<CityOverview> {
  CityData       _activeCity;
  CityData       _cityToAdd;
  List<CityData> _cityList;
  bool           _showSearch;
  List<String>   _apiResults;
  String         _cityName;

  // constructor
  CityOverviewState () {
    // read active city
    _showSearch    = false;
    _activeCity    = globals.activeCity;
    _cityList      = globals.savedCitys;
    _cityToAdd     = null;
    _apiResults = new List();

    if (_cityList == null) {
      _cityList = new List();
    }

    _cityList.add(new CityData(getNewId(), 'Freiburg', 79100));
    _cityList.add(new CityData(getNewId(), 'Bötzingen', 79268));
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent(_showSearch);
  }

  _buildContent(bool showSearch) {
    if (!showSearch) {
      return new Scaffold(
        appBar: new AppBar(
          // hand over function only like this: '() => funcName()'
          // with only 'funcName()' the function is called immediately after the builder is finished!
          // with only 'funcName' the function is not called at all!
          leading: new IconButton(icon: new Icon(Icons.arrow_back), onPressed: () => _goToActiveCity()),
          title: new Text('Saved City Overview'),
        ),
        body: _buildSavedCitys(),
        floatingActionButton: new FloatingActionButton(
            elevation: 0.0,
            child: new Icon(Icons.add),
            onPressed: () => setState(() {
              _showSearch = true;
            }), //() => _showBottomSheet(context)
        ),
      );
    } else {
      return new Scaffold(
        appBar: new AppBar(
          leading: new IconButton(icon: new Icon(Icons.clear), onPressed: () => setState(() {_showSearch = false;})),
          title: new TextField(
            style: new TextStyle(
              color: Colors.white,
              fontSize: 18.0,
            ),
            decoration: new InputDecoration.collapsed(
              hintStyle: new TextStyle(
                color: Colors.white30,
              ),
              hintText: 'Search City ...',
            ),
            onChanged: (cityName) => setState(() {
              _cityName = cityName;
            }),
          ),
        )
      );
    }
  }

  _addCityToList(BuildContext context) {
    // check for doubles
    // change list to object of city (name, plz, etc) for uniques

    if (_cityName != '') {
      _cityToAdd = new CityData(getNewId(), _cityName, 000); // TODO: add zip code
      setState(() {
        _cityList.add(_cityToAdd);
      });

      globals.savedCitys = _cityList;

      Navigator.pop(context);
    } else {
      // TODO: show toast
    }
  }

  _goToActiveCity () {
    // pushNamed would generate a route which can be navigated back
    // with pushReplacementNamed you basically switch between screens
    Navigator.of(context).pushReplacementNamed('/activeCity');
  }

  _deleteFromList(CityData cityData) {

    if (_activeCity == cityData) {
      _activeCity = null;
    }

    if (_cityList.contains(cityData)) {
      setState(() {
        _cityList.remove(cityData);
      });
    }

    globals.savedCitys = _cityList;
    globals.activeCity = _activeCity;
  }

  Widget _buildSavedCitys() {
    return new ListView(
      children: _cityList.map((CityData cityData) {
        return new ListTile(
            key: new ObjectKey(cityData.id),
            leading: new Icon(
              (_activeCity == cityData) ? Icons.star : Icons.star_border,
              color: (_activeCity == cityData) ? Colors.amber : null,
            ),
            title: new Text(cityData.name),
            trailing: new IconButton(
              icon: new Icon(Icons.delete_forever),
              onPressed: () => _deleteFromList(cityData),
            ),
            // set state, so that the icon will be updated
            onTap: () {
              setState(() {
                if (!(_activeCity == cityData)) {
                  // write raw string into activeCity
                  _activeCity = cityData;
                } else {
                  _activeCity = null;
                }
                // set active city for globals, no matter the outcome
                globals.activeCity = _activeCity;
              });
            }
        );
      }).toList(),
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
        body: _activeCity == null ? new Text('No Active City Set') : new Text(_activeCity.name)
    );
  }
}

