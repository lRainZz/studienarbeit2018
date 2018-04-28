import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'globals.dart' as globals;
import 'helper.dart';

// ===== ===== ===== =====
// TODO LIST
// ----- high priority -----
// ----- ----- ----- -----
//
// ----- low priority -----
// TODO: app logo cross with r-a-i-n lettering
// TODO: split classes into different files
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

class SettingsView extends StatefulWidget {
  @override
  createState() => SettingsViewState();
}

class SettingsViewState extends State<SettingsView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  bool _useImperialUnits;

  Widget _buildContent() {
    return new Column(
      children: <Widget>[
        new Padding(
          padding: new EdgeInsets.only(top: 10.0, bottom: 10.0),
          child:new SwitchListTile(
          value: _useImperialUnits,
          onChanged: (value) => _setUseImperial(value),
          title: new Text(
            'Use imperial units',
            style: new TextStyle(
              color: Colors.black45,
              fontSize: 20.0
              )
            )
          ),
        ),
        new Expanded(
          child: new Padding(
            padding: new EdgeInsets.all(20.0),
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                new Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    new Text(
                        'Weather data provided by',
                        style: new TextStyle(
                            color: Colors.black54
                        )
                    ),
                    new InkWell(
                      child: new Text(
                          ' apixu.com',
                          style: new TextStyle(
                              color: Colors.blueAccent
                          )
                      ),
                      onTap: () => launch('https://www.apixu.com/'),
                    )
                  ],
                ),
              ],
            )
          ),
        ),
      ],
    );
  }

  _setUseImperial(bool value) {
    globals.useImperial = value;

    setState(() {
      _useImperialUnits = value;
    });

    _scaffoldKey.currentState.showSnackBar(
      new SnackBar(
        content: new Text('Preferences updated'),
      )
    );
  }

  _goBack() {
    // update possible changed options
    globals.navRefresh = true;
    Navigator.of(context).pop();
  }

  SettingsViewState() {
    _useImperialUnits = globals.useImperial;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        backgroundColor: Colors.white,
        leading: new IconButton(
          icon: new Icon(
            Icons.arrow_back,
            color: Colors.black54
          ),
          onPressed: () => _goBack(),
        ),
        title: new Text(
          'Settings',
          style: new TextStyle(
            color: Colors.black54
          ),
        ),
      ),
      body: _buildContent()
    );
  }
}

class CityOverview extends StatefulWidget {
  @override
  createState() => CityOverviewState();

}

class CityOverviewState extends State<CityOverview> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  CityData       _activeCity;
  List<CityData> _cityList;
  bool           _showSearch;
  bool           _isLoading;
  bool           _noResults;
  List<CityData> _apiResults;
  String         _noResultPlaceholder;

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
    if (!_showSearch) {
      return new Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
          // hand over function only like this: '() => funcName()'
          // with only 'funcName()' the function is called immediately after the builder is finished!
          // with only 'funcName' the function is not called at all!
          leading: new IconButton(
            icon: new Icon(
              Icons.arrow_back,
              color: Colors.black54
            ),
            onPressed: () => _goToActiveCity()
          ),
          title: new Text(
            'Saved Citys',
            style: new TextStyle(
              color: Colors.black54
            )
          ),
          backgroundColor: Colors.white
        ),
        body: _buildSavedCitys(),
        floatingActionButton: new FloatingActionButton(
            elevation: 0.0,
            child: new Icon(
              Icons.add,
              color: Colors.white
            ),
            onPressed: () => setState(() {
              _showSearch = true;
            }), //() => _showBottomSheet(context)
        ),
      );
    } else {
      return new Scaffold(
          key: _scaffoldKey,
          appBar: new AppBar(
            backgroundColor: Colors.white,
            leading: new IconButton(
                icon: new Icon(
                  Icons.clear,
                  color: Colors.black54
                ),
                onPressed: () =>
                setState(() {
                  _showSearch = false;
                  _clearList();
                })),
            title: new TextField(
              style: new TextStyle(
                color: Colors.black,
                fontSize: 18.0,
              ),
              decoration: new InputDecoration.collapsed(
                hintStyle: new TextStyle(
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
          onTap: () => _addCityToList(cityData)
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

  _addCityToList(CityData cityData) {
    // check for doubles
    // change list to object of city (name, plz, etc) for uniques
    String snackMessage;

    // check doubles and set message
    if (_isDouble(cityData.name)) {

      snackMessage = "'" + cityData.name + "' is already in your list!";

    } else if (cityData != null) {
      // check for null (should not happen .. should)

      _clearList();

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
    _scaffoldKey.currentState.showSnackBar(
      new SnackBar(
        content: new Text(
          snackMessage
        ),
      )
    );
  }

  _goToActiveCity () {
    // clear results for next time
    _clearList();

    // update city data on screen change
    globals.needsUpdate = true;

    // update common data on screen change
    globals.navRefresh  = true;

    // pushNamed would generate a route which can be navigated back
    // with pushReplacementNamed you basically switch between screens
    // Navigator.of(context).pushReplacementNamed('/activeCity');

    // pop context for seamless transition
    Navigator.of(context).pop();
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
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  CityData _activeCity;
  bool     _useImperial;


  // constructor
  ActiveCityState() {
    _refreshData();
  }

  _refreshData() {
    // load globals
    _activeCity = globals.activeCity;
    _useImperial = globals.useImperial;

    if (_activeCity != null) {
      // refresh data
      if (globals.needsUpdate) {
        String requestURL = 'https://api.apixu.com/v1/current.json?key=' +
            API_KEY + '=' + _activeCity.name;

        http.get(requestURL)
            .then((response) => response.body)
            .then(json.decode)
            .then((apiData) {
          if (!apiCallHasError(apiData)) {
            _updateCity(apiData, _activeCity);
          }
        });

        globals.needsUpdate = false;
      }
    }
  }

  _goToCityOverview() {
    // pushName to allow using hardware / software back button to go to activeCity
    Navigator.of(context).pushNamed('/cityOverview');
  }

  _goToSettingsView() {
    Navigator.of(context).pushNamed('/settingsView');
  }

  AssetImage _getBackground() {
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

  Widget _buildContent(CityData activeCity) {
    if (globals.navRefresh) {
      globals.navRefresh = false;
      _refreshData();
    }

    return new Column(
      children: _chooseContent(activeCity),
    );
  }

  List<Widget> _chooseContent(CityData activeCity) {
    List<Widget> widgets = new List<Widget>();

    widgets.add(_buildTopContent());

    if (activeCity != null) {
      widgets.add(_buildMiddleContent(activeCity));
      widgets.add(_buildBottomContent(activeCity));
    } else {
      widgets.add(_buildInActiveContent());
    }

    return widgets;
  }

  Widget _buildInActiveContent() {
    return new Padding(
      padding: new EdgeInsets.only(top: 100.0),
      child: new Center(
        child:
        new Text(
          'NO ACTIVE CITY',
          style: new TextStyle(
            color: Colors.white,
            fontSize: 25.0
          )
        ),
      )
    );

  }

  _refreshCity(CityData activeCity) {
    // response to loading
    _scaffoldKey.currentState.showSnackBar(
      new SnackBar(
        content:
        new Row(
          children: <Widget>[
            new CircularProgressIndicator(),
            new Padding(
              padding: new EdgeInsets.only(left: 25.0),
              child: new Text(
                'Loading...'
              )
            ),
          ],
        ),
      )
    );

    String requestURL = 'https://api.apixu.com/v1/current.json?key=' + API_KEY + '=' +  activeCity.name;

    http.get(requestURL)
      .then((response) => response.body)
      .then(json.decode)
      .then((apiData) {
        if(!apiCallHasError(apiData)) {
          _updateCity(apiData, activeCity);
        }
      }); // no error catch

    // _scaffoldKey.currentState.removeCurrentSnackBar();
  }

  _updateCity(apiData, cityToRefresh) {
    var current  = apiData['current'];
    var location = apiData['location'];

    Weather  weather  = mapWeather(current);
    CityData newCityData = mapCityData(location, weather);

    int index = globals.savedCitys.indexOf(cityToRefresh);

    globals.savedCitys[index] = newCityData;
    globals.activeCity = newCityData;

    setState(() {
      _activeCity = newCityData;
    });
  }

  double _getConditionTextSize(String condition) {
    int textSize = condition.length;
    double result;

    textSize >= 40 ? result = 11.0 : (textSize >= 32 ? result = 14.0 : (textSize > 26 ? result = 16.0 : result = 20.0));

    return result;
  }

  Widget _buildTopContent() {
    return new Padding(
      padding: new EdgeInsets.only(left: 25.0, right: 25.0, bottom: 10.0),
      child: new Row(
        children: <Widget>[
          new Expanded(
            child: new Align(
              child: new InkWell(
                child: new Icon(Icons.info, size: 25.0, color: Colors.white),
                onTap: () => _goToSettingsView(),
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
    );
  }

  Widget _buildMiddleContent(CityData activeCity) {
    return new Column(
      children: <Widget>[
        new Center(
          child: new Text(
              geTimeFromDateTime(activeCity.localtime + '   '),
              style: new TextStyle(
                  color: Colors.white,
                  fontSize: 20.0
              )
          ),
        ),
        new Center(
          child: new Padding(
            padding: EdgeInsets.only(bottom: 30.0),
            child: new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new InkWell(
                  onTap: () => _refreshCity(activeCity),
                  child: new Text(
                    '   ' + activeCity.name + '   ',
                    style: new TextStyle(
                      color: Colors.white,
                      fontSize: 30.0,
                    )
                  ),
                ),
                new InkWell(
                    onTap: () => _refreshCity(activeCity),
                    child: new Icon(
                        Icons.refresh,
                        color: Colors.white30,
                        size: 30.0
                    )
                ),
              ],
            ),
          ),
        ),
        new Center(
          child: new Text(
            (_useImperial ? activeCity.weather.tempF.round().toString() : activeCity.weather.tempC.round().toString()) + '°',
            style: new TextStyle(
                color: Colors.white,
                fontSize: 80.0,
            ),
          ),
        ),
        new Center(
            child: new Text(
              'Feels like ' + ( _useImperial ? activeCity.weather.feelsLikeF.round().toString() : activeCity.weather.feelsLikeC.round().toString()) + '°',
              style: new TextStyle(
                color: Colors.white,
                fontSize: 17.5,
              ),
            )
        ),
      ],
    );
  }

  Widget _buildBottomContent(CityData activeCity) {
    return new Expanded(
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          new Container(
            decoration: new BoxDecoration(
              color: Colors.black45,
            ),
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new Padding(
                  padding: new EdgeInsets.only(left: 25.0, right: 10.0, top: 5.0, bottom: 5.0),
                  child: new Row(
                    children: <Widget>[
                      new Expanded(
                        child: new Align(
                          alignment: Alignment.centerLeft,
                          child: new Text(
                            'Condition',
                            style: _getBottomTextStyle()
                          )
                        ),
                      ),
                      new Expanded(
                        flex: 2,
                        child:new Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            new Text(
                              activeCity.weather.condition,
                              style: new TextStyle(
                                  color: Colors.white,
                                  fontSize: _getConditionTextSize(activeCity.weather.condition)
                              )
                            ),
                            new Image.network(
                              activeCity.weather.conditionIcon,
                              width:  50.0,
                              height: 50.0
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                new Divider(color: Colors.white, height: 1.0),
                new Padding(
                  padding: new EdgeInsets.only(left: 25.0, right: 25.0, top: 15.0, bottom: 15.0),
                  child: new Row(
                    children: <Widget>[
                      new Expanded(
                        child: new Align(
                          child: new Text(
                            'Wind "' + activeCity.weather.windDirection + '"',
                            style: _getBottomTextStyle()
                          ),
                          alignment: Alignment.centerLeft,
                        )
                      ),
                      new Expanded(
                        child: new Align(
                          child: new Text(
                              _useImperial ? activeCity.weather.windMph.toString() + ' mph' : activeCity.weather.windKph.toString() + ' kph',
                            style: _getBottomTextStyle()
                          ),
                          alignment: Alignment.centerRight,
                        )
                      )
                    ],
                  ),
                ),
                new Divider(color: Colors.white, height: 1.0),
                new Padding(
                  padding: new EdgeInsets.only(left: 25.0, right: 25.0, top: 15.0, bottom: 15.0),
                  child: new Row(
                    children: <Widget>[
                      new Expanded(
                        child: new Align(
                          alignment: Alignment.centerLeft,
                          child: new Text(
                            'Humidity',
                            style: _getBottomTextStyle()
                          )
                        )
                      ),
                      new Expanded(
                        child: new Align(
                          alignment: Alignment.centerRight,
                          child: new Text(
                            activeCity.weather.humidity.toString() + ' %',
                            style: _getBottomTextStyle()
                          )
                        )
                      )
                    ],
                  ),
                ),
              ],
            )
          ),
        ],
      ),
    );
  }

  TextStyle _getBottomTextStyle() {
    return new TextStyle(
      color: Colors.white,
      fontSize: 20.0
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      body: new Container(
        padding: const EdgeInsets.only(top: 35.0),
        constraints: new BoxConstraints.expand(
          // full hd
          height: 1920.0,
          width: 1080.0,
        ),
        decoration: new BoxDecoration(
          image: new DecorationImage(
            image: _getBackground(),
            fit: BoxFit.fill
          )
        ),
        child: _buildContent(_activeCity)
      ),
    );
  }
}

