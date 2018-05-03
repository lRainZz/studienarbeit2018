import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'globals.dart' as globals;
import 'helper.dart';
import 'dbConnection.dart';

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
  DBConnection   _dbConnection;

  final _subject = new PublishSubject<String>();

  // constructor
  CityOverviewState () {
    _dbConnection  = globals.con;
    _showSearch    = false;
    _isLoading     = false;
    _noResults     = false;

    _dbConnection.getAllCitys().then(
      (cityList) {
        setState(() {
          _cityList = cityList;
          _activeCity = getActiveCity(cityList);
        });
      }
    );

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
      _clearSearchList();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _clearSearchList();

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

  _clearSearchList() {
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
    CityData cityData = mapCityData(location, weather, false);

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
                      _clearSearchList();
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

      _clearSearchList();

      _dbConnection.setCityData(cityData).then(
          (idTuple) {
            cityData.setId(idTuple[0]);
            cityData.weather.setId(idTuple[1]);

            setState(() {
              _cityList.add(cityData);
              _showSearch = false;
            });
          }
      );

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
    _clearSearchList();

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
      cityData.setActive(false);
      _dbConnection.updateCity(cityData);
    }

    if (_cityList.contains(cityData)) {
      _dbConnection.deleteCity(cityData);
      setState(() {
        _cityList.remove(cityData);
      });
    }
  }

  _setAsActive (cityData) {
    setState(() {
      if (!(_activeCity == cityData)) {
        _activeCity = cityData;
        cityData.setActive(true);
      } else {
        _activeCity = null;
      }
      // update active state in db
      _dbConnection.updateCity(cityData);
    });
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
            onTap: () => _setAsActive(cityData),
        );
      }).toList(),
    );
  }
}