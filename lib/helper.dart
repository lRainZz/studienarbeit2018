import 'globals.dart' as globals;
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
  final int    id;
  final String name;
  final String region;
  final String localtime;
  final Weather weather;

  const CityData(
      this.id,
      this.name,
      this.region,
      this.weather,
      this.localtime
  );
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

  const Weather(
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

}

Weather mapWeather(dynamic weatherJSON) {
  String lastUpdated   = weatherJSON['last_updated'];
  double tempC         = weatherJSON['temp_c'];
  double tempF         = weatherJSON['temp_f'];
  double feelsLikeC    = weatherJSON['feelslike_c'];
  double feelsLikeF    = weatherJSON['feelslike_f'];
  bool   isDay         = (weatherJSON['is_day'] == 1);
  String condition     = weatherJSON['condition']['text'];
  String conditionIcon = weatherJSON['condition']['icon'];
  String windDirection = weatherJSON['wind_dir'];
  double windKph       = weatherJSON['wind_kph'];
  double windMph       = weatherJSON['wind_mph'];
  int    humidity      = weatherJSON['humidity'];

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

CityData mapCityData(dynamic cityDataJSON, Weather weather) {
  int    id        = getNewId();
  String name      = cityDataJSON['name'];
  String region    = cityDataJSON['region'];
  String localtime = cityDataJSON['localtime'];

  return new CityData(
    id,
    name,
    region,
    weather,
    localtime
  );
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
  if (timeString[11] != ':') {
    timeString = datePart + ' 0' + timePart;
  }

  return timeString;
}

int getNewId() {
  int id = globals.currentId;
  globals.currentId = id + 1;
  return id;
}