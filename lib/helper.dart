import 'globals.dart' as globals;

// class for defining a new simple type of CityData
class CityData {
  final int    id;
  final String name;
  final String region;
  final Weather weather;

  const CityData(
      this.id,
      this.name,
      this.region,
      this.weather
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
  double tempC         = weatherJSON['temp_C'];
  double tempF         = weatherJSON['temp_F'];
  double feelsLikeC    = weatherJSON['feelslike_C'];
  double feelsLikeF    = weatherJSON['feelslike_F'];
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
  int    id     = getNewId();
  String name   = cityDataJSON['name'];
  String region = cityDataJSON['region'];

  return new CityData(
    id,
    name,
    region,
    weather
  );
}

int getNewId() {
  int id = globals.currentId;
  globals.currentId = id + 1;
  return id;
}