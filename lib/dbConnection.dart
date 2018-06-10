import 'dart:io';
import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'helper.dart';

class DBConnection {
  String   _dbPath;
  Database _dbCon;

  DBConnection() {
    // _init();
  }

  bool established() {
    return _dbCon != null;
  }

  Future<dynamic> init() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    _dbPath = join(documentsDirectory.path, 'rain.db');

    _dbCon = await openDatabase(
      _dbPath,
      version: 1,
      onCreate: (Database db,  int version)  async {
        // create tables upon creating Database
        String sqlTableSavedCitys = 'CREATE TABLE SavedCitys ('
                                    // rowid is given by sqlite upon making inserts!
                                    'isActive   INTEGER DEFAULT 0, '
                                    'name       TEXT NOT NULL, '
                                    'region     TEXT, '
                                    'localtime  TEXT NOT NULL, '
                                    'ID_weather INTEGER NOT NULL, '
                                    'FOREIGN KEY(ID_weather) REFERENCES CityWeather(rowid)'
                                    ');';

        String sqlCityWeather     = 'CREATE TABLE CityWeather ('
                                    // rowid is given by sqlite upon making inserts!
                                    'lastUpdated   TEXT NOT NULL, '
                                    'tempC         REAL NOT NULL, '
                                    'tempF         REAL NOT NULL, '
                                    'feelsLikeC    REAL NOT NULL, '
                                    'feelsLikeF    REAL NOT NULL, '
                                    'isDay         INTEGER NOT NULL, ' // bool
                                    'condition     TEXT NOT NULL, '
                                    'conditionIcon TEXT NOT NULL, '
                                    'windDirection TEXT NOT NULL, '
                                    'windKph       REAL NOT NULL, '
                                    'windMph       REAL NOT NULL, '
                                    'humidity      INTEGER NOT NULL'
                                    ')';

        String sqlTableSettings   = 'CREATE TABLE Settings ('
                                    'useImperial INTEGER NOT NULL ' // bool
                                    ')';

        String sqlBaseSettings    = 'INSERT INTO Settings(useImperial) VALUES (0)';

        await db.execute(sqlTableSavedCitys);
        await db.execute(sqlCityWeather);
        await db.execute(sqlTableSettings);
        await db.execute(sqlBaseSettings);
      }
    );

    return;
  }

  Future<bool> getSettings() async{
    return await _loadSettings();
  }

  Future<bool> _loadSettings() async{

    String sql = 'SELECT * FROM Settings WHERE rowid = 1';
    List<Map> results = await _dbCon.rawQuery(sql);

    return results[0]['useImperial'] == 1;
  }

  Future<bool> setSettings(bool useImperial) async{
    return await _updateSettings(useImperial);
  }

  Future<bool>_updateSettings(bool useImperial) async{
    String sql = 'UPDATE Settings SET useImperial = ' + (useImperial ? '1' : '0') + ' WHERE rowid = 1';
    await _dbCon.rawUpdate(sql);
    return true;
  }

  deleteCity(CityData cityData) async{
    await _deleteCityData(cityData);
  }

  _deleteCityData(CityData cityData) async{
    String sqlDeleteWeather  = 'DELETE FROM CityWeather WHERE rowid = ' + cityData.weather.id.toString();
    String sqlDeleteCityData = 'DELETE FROM SavedCitys  WHERE rowid = ' + cityData.id.toString();

    await _dbCon.transaction((txn) async{
      await txn.rawDelete(sqlDeleteWeather);
      await txn.rawDelete(sqlDeleteCityData);
    });
  }

  Future<bool> updateCity(CityData cityData) async {
    await _updateCityData(cityData);
    return true;
  }

  _updateCityData(CityData cityData) async{
    String sqlCityWeather = 'UPDATE CityWeather '
                            'SET '
                            'lastUpdated = "'   + cityData.weather.lastUpdated + '", '
                            'tempC = '          + cityData.weather.tempC.toString() + ', '
                            'tempF = '          + cityData.weather.tempF.toString() + ', '
                            'feelsLikeC = '     + cityData.weather.feelsLikeC.toString() + ', '
                            'feelsLikeF = '     + cityData.weather.feelsLikeF.toString() + ', '
                            'isDay = '          + (cityData.weather.isDay ? '1' : '0') + ', '
                            'condition = "'     + cityData.weather.condition + '", '
                            'conditionIcon = "' + cityData.weather.conditionIcon + '", '
                            'windDirection = "' + cityData.weather.windDirection + '", '
                            'windKph = '        + cityData.weather.windKph.toString() + ', '
                            'windMph = '        + cityData.weather.windMph.toString() + ', '
                            'humidity = '       + cityData.weather.humidity.toString() + ' '
                            'WHERE rowid = '    + cityData.weather.id().toString();


    String sqlCityData =    'UPDATE SavedCitys '
                            'SET '
                            'name = "'        + cityData.name + '", '
                            'region = "'      + cityData.region + '", '
                            'localtime = "'   + cityData.localtime + '", '
                            'isActive = '     + (cityData.isActive() ? '1' : '0') + ' '
                            'WHERE rowid = '  + cityData.id().toString();

    await _dbCon.transaction((txn) async{
      await txn.rawUpdate(sqlCityWeather);
      await txn.rawUpdate(sqlCityData);
    });
  }

  Future<dynamic> setCityData(CityData cityData) async{
    return await _insertCity(cityData);
  }

  Future<dynamic> _insertCity(CityData cityData) async{
    var idTuple = new List(2);

    String sqlWeatherData = 'INSERT INTO CityWeather('
                            'lastUpdated, '
                            'tempC, '
                            'tempF, '
                            'feelsLikeC, '
                            'feelsLikeF, '
                            'isDay, '
                            'condition, '
                            'conditionIcon, '
                            'windDirection, '
                            'windKph, '
                            'windMph,'
                            'humidity) '
                            'VALUES (' +
                            '"' + cityData.weather.lastUpdated + '", ' +
                            cityData.weather.tempC.toString() + ', ' +
                            cityData.weather.tempF.toString() + ', ' +
                            cityData.weather.feelsLikeC.toString() + ', ' +
                            cityData.weather.feelsLikeF.toString() + ', ' +
                            (cityData.weather.isDay ? '1' : '0') + ', ' +
                            '"' + cityData.weather.condition + '", ' +
                            '"' + cityData.weather.conditionIcon + '", ' +
                            '"' + cityData.weather.windDirection + '", ' +
                            cityData.weather.windKph.toString() + ', ' +
                            cityData.weather.windMph.toString() + ', ' +
                            cityData.weather.humidity.toString() +
                            ')';

    await _dbCon.transaction((txn) async {
      String sqlCityData;

      await txn.rawInsert(sqlWeatherData).then(
          (newId) {
            idTuple[0] = newId;

            sqlCityData = 'INSERT INTO SavedCitys('
                'isActive, '
                'name, '
                'region, '
                'localtime, '
                'ID_weather'
                ') '
                'VALUES (' +
                (cityData.isActive() ? '1' : '0') + ', ' +
                '"' + cityData.name + '", ' +
                '"' + cityData.region + '", ' +
                '"' + cityData.localtime + '", ' +
                newId.toString() +
                ')';
          }
      );

      await txn.rawInsert(sqlCityData).then((newId) {idTuple[1] = newId;});
    });

    return idTuple;
  }

  Future<List<CityData>> getAllCitys() async{
    return await _loadAllCitys();
  }

  Future<List<CityData>> _loadAllCitys() async {
    List<CityData> _allCitys = new List<CityData>();

    String sql = 'SELECT rowid, * FROM SavedCitys';

    List<Map> savedCitysResults = await _dbCon.rawQuery(sql);
    List<Weather> weatherList   = await  _loadAllWeather();

    savedCitysResults.forEach(
      (result) {
        CityData cityData = new CityData(
          result['name'],
          result['region'],
          _getWeatherByID(result['ID_weather'], weatherList),
          result['localtime']
        );

        cityData.setId(result['rowid']);

        cityData.setActive(result['isActive'] == 1);

        _allCitys.add(cityData);
      }
    );
    return _allCitys;
  }

  Weather _getWeatherByID(int id, List<Weather> weatherList) {
    Weather result;

    weatherList.forEach(
      (weather) {
        if (weather.id() == id) result = weather;
      }
    );
    return result;
  }

  _loadAllWeather() async {
    List<Weather> _allWeather = new List<Weather>();

    String sql = 'SELECT rowid, * FROM CityWeather';

    List<Map> cityWeatherResults = await _dbCon.rawQuery(sql);

    cityWeatherResults.forEach(
      (result) {
        Weather weather = new Weather(
          result['lastUpdated'],
          result['tempC'],
          result['tempF'],
          result['feelsLikeC'],
          result['feelsLikeF'],
          result['isDay'] == 1,
          result['condition'],
          result['conditionIcon'],
          result['windDirection'],
          result['windKph'],
          result['windMph'],
          result['humidity']
        );

        weather.setId(result['rowid']);

        _allWeather.add(weather);
      }
    );
    return _allWeather;
  }
}