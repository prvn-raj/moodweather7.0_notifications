import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';

class WeatherService {
  final String apiKey = 'cbb938da63f7c6c7e32a7518e3ea2f59';
  final Location _location = Location();

  Future<LocationData> _getLocation() async {
    // On a cold app start, the location plugin's Android service can still be
    // binding when the first call arrives, throwing SERVICE_STATUS_ERROR. Retry
    // briefly rather than surfacing a spurious failure to the user.
    for (int attempt = 0; ; attempt++) {
      try {
        return await _tryGetLocation();
      } on PlatformException catch (e) {
        if (e.code != 'SERVICE_STATUS_ERROR' || attempt >= 3) rethrow;
        await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
      }
    }
  }

  Future<LocationData> _tryGetLocation() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }
    }

    PermissionStatus permission = await _location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await _location.requestPermission();
    }
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.grantedLimited) {
      throw Exception('Location permission denied');
    }

    return await _location.getLocation();
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
