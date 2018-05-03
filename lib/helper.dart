import 'dart:core';

// constants
const String API_KEY = '0bc7502d2189494ca7492757182204&q';

const String ASSET_BG_BLACKWHITE = 'res/img/AppLandScape_bw.png';
const String ASSET_BG_NIGHTTIKME = 'res/img/AppLandScape_night.png';
const String ASSET_BG_SUNRISE    = 'res/img/AppLandScape_sunrise_vibrant.png';
const String ASSET_BG_DAYTIME    = 'res/img/AppLandScape_day.png';

// DateTime(year, month, day, hour, minute, second, millisecond,microsecond, false)
final int sunriseBegin = 5;  //  5 o'clock);
final int sunriseEnd   = 9;  //  9 o'clock);
final int sunsetBegin  = 17; // 17 o'clock);
final int sunsetEnd    = 21; // 21 o'clock);


// class for defining a new simple type of CityData
class CityData {
  final String name;
  final String region;
  final String localtime;
  final Weather weather;

  int  _id;
  bool _isActive = false;

  CityData(
      this.name,
      this.region,
      this.weather,
      this.localtime
  );

  setId(int id) {
    _id = id;
  }

  id() {
    return _id;
  }

  isActive() {
    return _isActive;
  }

  setActive(bool active) {
    _isActive = active;
  }
}

// class for defining a new simple type of Weather for CityData
class Weather {
  final String lastUpdated;
  final double tempC;
  final double tempF;
  final double feelsLikeC;
  final double feelsLikeF;
  final bool   isDay;
  final String condition;
  final String conditionIcon;
  final String windDirection;
  final double windKph;
  final double windMph;
  final int    humidity;

  int _id;

  Weather(
    this.lastUpdated,
    this.tempC,
    this.tempF,
    this.feelsLikeC,
    this.feelsLikeF,
    this.isDay,
    this.condition,
    this.conditionIcon,
    this.windDirection,
    this.windKph,
    this.windMph,
    this.humidity
  );

  setId(int id) {
    _id = id;
  }

  id() {
    return _id;
  }

}

Weather mapWeather(dynamic weatherJSON) {
  String lastUpdated   =            weatherJSON['last_updated'];
  double tempC         =            weatherJSON['temp_c'];
  double tempF         =            weatherJSON['temp_f'];
  double feelsLikeC    =            weatherJSON['feelslike_c'];
  double feelsLikeF    =            weatherJSON['feelslike_f'];
  bool   isDay         =           (weatherJSON['is_day'] == 1);
  String condition     =            weatherJSON['condition']['text'];
  String conditionIcon = 'https:' + weatherJSON['condition']['icon']; // URL must have protocol
  String windDirection =            weatherJSON['wind_dir'];
  double windKph       =            weatherJSON['wind_kph'];
  double windMph       =            weatherJSON['wind_mph'];
  int    humidity      =            weatherJSON['humidity'];

  return new Weather(
    lastUpdated,
    tempC,
    tempF,
    feelsLikeC,
    feelsLikeF,
    isDay,
    condition,
    conditionIcon,
    windDirection,
    windKph,
    windMph,
    humidity
  );
}

CityData getActiveCity(List<CityData> cityDatas) {
  if (cityDatas == null) return null;

  CityData activeCity;
  cityDatas.forEach(
    (cityData) {
      if (cityData.isActive()) activeCity = cityData; return;
    }
  );

  return activeCity;
}


CityData mapCityData(dynamic cityDataJSON, Weather weather, bool isActive, [int idOld = 0]) {
  int    id        = idOld;
  String name      = cityDataJSON['name'];
  String region    = cityDataJSON['region'];
  String localtime = cityDataJSON['localtime'];

  CityData cityData = new CityData(
    name,
    region,
    weather,
    localtime
  );

  cityData.setId(id);

  cityData.setActive(isActive);

  return cityData;
}

String getTimeSyntaxLeadingZero(String timeString) {
  String timePart;
  String datePart;
  var dateTimeArray;

  dateTimeArray = timeString.split(' ');
  datePart = dateTimeArray[0];
  timePart = dateTimeArray[1];
  // position 11 of string must be ':'
  // otherwise a leading 0 is missing!
  if (timePart[2] != ':') {
    timeString = datePart + ' 0' + timePart;
  }

  return timeString;
}

String geTimeFromDateTime(String timeString) {
  return timeString.split(' ')[1];
}

bool apiCallHasError(apiData) {
  bool result = true;
  // API Error codes: https://www.apixu.com/doc/errors.aspx
  int errorCode;

  // check if data contains error object
  // if not do not trigger error handling
  if (apiData['error'] != null) {
    errorCode = apiData['error']['code'];
  } else errorCode = 0;

  // handling all possible errors in the same way
  if (/*HTTP 400*/ errorCode != 1003 && errorCode != 1005 && errorCode != 1006 && errorCode != 9999 &&
      /*HTTP 401*/ errorCode != 1002 && errorCode != 2006 &&
      /*HTTP 403*/ errorCode != 2007 && errorCode != 2008) {
    result = false;
  }

  return result;
}