import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';

class WeatherService {
  final String apiKey = 'cbb938da63f7c6c7e32a7518e3ea2f59';

  Future<LocationData> _getLocation() async {
    return await Location().getLocation();
  }

  /// Returns condition, icon, temperature, city, and country in one API call.
  Future<Map<String, dynamic>> fetchWeather() async {
    final loc = await _getLocation();
    final response = await http.get(Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather'
      '?lat=${loc.latitude}&lon=${loc.longitude}'
      '&appid=$apiKey&units=metric',
    ));

    if (response.statusCode == 200) {
      final j = json.decode(response.body);
      return {
        'condition':   j['weather'][0]['main'],
        'icon':        j['weather'][0]['icon'],
        'temperature': (j['main']['temp'] as num).toStringAsFixed(0),
        'city':        j['name'],
        'country':     j['sys']['country'],
      };
    } else {
      throw Exception('Failed to load weather');
    }
  }

  Future<List<Map<String, dynamic>>> fetch5DayForecast() async {
    final loc = await _getLocation();
    final response = await http.get(Uri.parse(
      'https://api.openweathermap.org/data/2.5/forecast'
      '?lat=${loc.latitude}&lon=${loc.longitude}'
      '&cnt=40&appid=$apiKey&units=metric',
    ));

    if (response.statusCode == 200) {
      final j = json.decode(response.body);
      return (j['list'] as List).cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load weather forecast');
    }
  }

  /// Kept for backward compatibility — prefer fetchWeather() which returns city too.
  Future<String> fetchCityName() async {
    final weather = await fetchWeather();
    return weather['city'] as String;
  }
}
