import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';

class WeatherService {
  final String apiKey = 'cbb938da63f7c6c7e32a7518e3ea2f59';

  Future<Map<String, dynamic>> fetchWeather() async {
    Location location = new Location();
    LocationData? locationData;
    locationData = await location.getLocation();
    final response = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=${locationData.latitude}&lon=${locationData.longitude}&appid=$apiKey&units=metric'));

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      return {
        'condition': jsonResponse['weather'][0]['main'],
        'icon': jsonResponse['weather'][0]['icon'],
        'temperature': jsonResponse['main']['temp'].toStringAsFixed(0) // Convert temperature to integer
      };
    } else {
      throw Exception('Failed to load weather');
    }
  }

  Future<List<Map<String, dynamic>>> fetch5DayForecast() async {
    Location location = new Location();
    LocationData? locationData;
    locationData = await location.getLocation();
    final response = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?lat=${locationData.latitude}&lon=${locationData.longitude}&cnt=40&appid=$apiKey&units=metric')); // 5 days * 8 (3-hour intervals) = 40

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      return (jsonResponse['list'] as List).cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load weather forecast');
    }
  }

  Future<String> fetchCityName() async {
    Location location = new Location();
    LocationData? locationData;
    locationData = await location.getLocation();
    final response = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=${locationData.latitude}&lon=${locationData.longitude}&appid=$apiKey'));

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      return jsonResponse['name']; // This will give the city name
    } else {
      throw Exception('Failed to load city name');
    }
  }
}
