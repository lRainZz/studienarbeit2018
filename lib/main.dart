import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'globals.dart' as globals;
import 'helper.dart';

// ===== ===== ===== =====
// TODO LIST
// ----- high priority -----
// TODO: display data of active city on active city screen
// TODO: swipe to go to city overview
// TODO: useful refresh of data (activeCity changes / pull to refresh)
// TODO: refresh modal
// TODO: api timeout
// TODO: credits for apixu
// ----- ----- ----- -----
//
// ----- low priority -----
// TODO: setting for imperial / metric units
// TODO: app logo cross with r-a-i-n lettering
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
  List<CityData> _cityList;
  bool           _showSearch;
  bool           _isLoading;
  bool           _noResults;
  List<CityData> _apiResults;
  String         _noResultPlaceholder = '';

  final _subject = new PublishSubject<String>();

  // constructor
  CityOverviewState () {
    // read active city
    _showSearch    = false;
    _isLoading     = false;
    _noResults     = false;
    _activeCity    = globals.activeCity;
    _cityList      = globals.savedCitys;
    _apiResults    = new List();

    if (_cityList == null) {
      _cityList = new List();
    }

    _subject.stream.debounce(new Duration(milliseconds: 600)).listen(_nameChanged);
  }

  _nameChanged(String cityName) {
    if (cityName.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      _clearList();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _clearList();

    String requestURL = 'https://api.apixu.com/v1/current.json?key=' + API_KEY + '=' +  cityName;

    http.get(requestURL)
      .then((response) => response.body)
      .then(json.decode)
      .then((apiData) {

          // API Error codes: https://www.apixu.com/doc/errors.aspx
          int errorCode;

          // check if data contains error object
          // if not do not trigger error handling
          if (apiData['error'] != null) {
            errorCode = apiData['error']['code'];
          } else errorCode = 0;

          // TODO: different actions for different HTTP status codes
          // handling all possible errors in the same way
          if ( /*HTTP 400*/ errorCode == 1003 || errorCode == 1005 || errorCode == 1006 || errorCode == 9999 ||
               /*HTTP 401*/ errorCode == 1002 || errorCode == 2006 ||
               /*HTTP 403*/ errorCode == 2007 || errorCode == 2008) {

            setState(() {
              _noResults = true;
              _noResultPlaceholder = cityName;
            });
          } else {
            _addCity(apiData);
          }
        })
      .catchError(_onError)
      .then((e) {setState(() {
          _isLoading = false;
        });
      });
  }

  _onError(dynamic d) {
    print(d);
    setState(() {
      _isLoading = false;
    });
  }

  _clearList() {
    setState(() {
      _noResults = false;
      _noResultPlaceholder = '';
      _apiResults.clear();
    });
  }

  _addCity(dynamic apiCity) {
    var current  = apiCity['current'];
    var location = apiCity['location'];

    Weather  weather  = mapWeather(current);
    CityData cityData = mapCityData(location, weather);

    setState(() {
      _apiResults.add(cityData);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent(context, _showSearch);
  }

  _buildContent(BuildContext context, bool showSearch) {
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
            leading: new IconButton(
                icon: new Icon(Icons.clear), onPressed: () =>
                setState(() {
                  _showSearch = false;
                  _clearList();
                })),
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
              onChanged: (cityName) => (_subject.add(cityName)),
            ),
          ),
          body: _isLoading ? _showLoadingScreen() : new Container(
              child: new ListView(
                padding: new EdgeInsets.all(16.0),
                children: _buildResultList(context, _apiResults),
              )
          )
      );
    }
  }

  Widget _showLoadingScreen() {
    return new Container(
      child: new Center(
        child: new CircularProgressIndicator()
      ),
    );
  }

  List<Widget> _buildResultList(BuildContext context, List<CityData> apiResults) {
    if (_noResults) {
      List<Widget> result = new List<Widget>();

      result.add(
        new ListTile(
          leading: new Icon(Icons.cancel),
          title: new Text(
            "No Results for '" + _noResultPlaceholder + "'",
            // style: new TextStyle(color: Colors.white30),
          ),
        )
      );

      return result;
    }

    return apiResults.map((CityData cityData) {
      return new ListTile(
          key: new ObjectKey(cityData.id),
          leading: new Icon(Icons.search),
          title: new Text (cityData.name),
          onTap: () => _addCityToList(context, cityData)
      );
    }).toList();
  }

  bool _isDouble(String cityName) {
    bool result = false;

    for (CityData city in _cityList) {
      if (city.name == cityName) {
        result = true;
      }
    }

    return result;
  }

  _addCityToList(BuildContext context, CityData cityData) {
    // check for doubles
    // change list to object of city (name, plz, etc) for uniques
    String snackMessage = '';

    // check doubles and set message
    if (_isDouble(cityData.name)) {

      snackMessage = "'" + cityData.name + "' is already in your list!";

    } else if (cityData != null) {
      // check for null (should not happen .. should)
      setState(() {
        _cityList.add(cityData);
        _showSearch = false;
      });

      globals.savedCitys = _cityList;

      snackMessage = "'" + cityData.name + "' was added to your city list.";

    } else {
      // on error set message
      snackMessage = "Could't add city to list. Pleas try again";
    }
      // view snackbar with given message
      // Scaffold.of(context).showSnackBar(
      //     new SnackBar(
      //         content: new Text(snackMessage)
      //     )
      // );
  }

  _goToActiveCity () {
    // clear results for next time
    _clearList();

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
      padding: new EdgeInsets.all(16.0),
      children: _cityList.map((CityData cityData) {
        return new ListTile(
            key: new ObjectKey(cityData.id),
            leading: new Icon(
              (_activeCity == cityData) ? Icons.check_box : Icons.check_box_outline_blank,
              color: (_activeCity == cityData) ? Colors.green : null,
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
  CityData _activeCity;

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

  AssetImage getBackground() {
    String assetName;
    DateTime localtime;
    CityData activeCity = globals.activeCity;

    if (activeCity == null) {
      // no active city set
      assetName = ASSET_BG_BLACKWHITE;
    } else {
      // get current time if active city
      localtime = DateTime.parse(getTimeSyntaxLeadingZero(activeCity.localtime)); // '2018-04-27 8:08:00'

      if ((localtime.hour > sunriseBegin && localtime.hour < sunriseEnd)
       || (localtime.hour > sunsetBegin  && localtime.hour < sunsetEnd)) {
        // between sunrise/sunset time
        assetName = ASSET_BG_SUNRISE;
      } else {
        // not sunrise/sunset
        // check for day or night
        activeCity.weather.isDay ? assetName = ASSET_BG_DAYTIME : assetName = ASSET_BG_NIGHTTIKME;
      }
    }

    return new AssetImage(assetName);
  }

  Widget buildContent(CityData activeCity) {

    if (activeCity == null) {
      // return info and button for cityList
    } else {
      return new Column(
        children: <Widget>[
          new Padding(
            padding: new EdgeInsets.only(bottom: 80.0),
            child: new Row(
              children: <Widget>[
                new Expanded(
                  child: new Align(
                    child: new InkWell(
                      child: new Icon(Icons.info, size: 25.0, color: Colors.white),
                      onTap: null,
                    ),
                    alignment: Alignment.centerLeft,
                  ),
                ),
                new Expanded(
                  child: new Align(
                    child: new InkWell(
                      child: new Icon(Icons.list, size: 30.0, color: Colors.white),
                      onTap: () => _goToCityOverview(),
                    ),
                    alignment: Alignment.centerRight,
                  )
                ),
              ],
            ),
          ), // Info Button and List Button
          new Center(
            child: new Text(
              activeCity.weather.tempC.toString() + '°',
              style: new TextStyle(
                color: Colors.white,
                fontSize: 75.0
              ),
            ),
          ),
          new Center(
              child: new Text(
                'Feels like ' + activeCity.weather.feelsLikeC.toString() + '°',
                style: new TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                ),
              )
          ),
          new Expanded(
            child: new Align(
              alignment: Alignment.bottomCenter,
              child: buildContentBottom(activeCity),
            ),
          ),
        ],
      );
    }
  }

  Widget buildContentBottom(CityData activeCity) {

    return new Text('Hello World');
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        body: new Container(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 35.0),
            constraints: new BoxConstraints.expand(
              // full hd
              height: 1920.0,
              width: 1080.0,
            ),
            decoration: new BoxDecoration(
                image: new DecorationImage(
                    image: getBackground(),
                    fit: BoxFit.fill
                )
            ),
          child: buildContent(globals.activeCity)
        )
    );
  }
}

