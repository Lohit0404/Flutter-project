import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherService {
  Stream<Map<String, dynamic>> weatherStream() async* {
    while (true) {
      final data = await fetchWeather(); // Your API call method
      yield data;
      await Future.delayed(const Duration(seconds: 30)); // Refresh every 30s
    }
  }

  Future<Map<String, dynamic>> fetchWeather() async {
    final lat = 8.54689684405744;
    final lon = 76.87949028170128;

    final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final weather = body['current_weather'];
      return {
        'temperature': '${weather['temperature']}°C',
        'location': 'Thiruvananthapuram', // or use reverse geocoding if needed
        'emoji': _getWeatherEmoji(weather['weathercode']),
      };
    } else {
      throw Exception('Failed to load weather');
    }
  }

  String _getWeatherEmoji(int code) {
    switch (code) {
      case 0:
        return '☀️';
      case 1:
        return '🌤️';
      case 2:
        return '⛅';
      case 3:
        return '☁️';
      case 61:
        return '🌧️';
      case 71:
        return '🌨️';
      case 95:
        return '⛈️';
      default:
        return '🌚';
    }
  }
}
