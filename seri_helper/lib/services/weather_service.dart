import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// WeatherService manages GPS-based environmental data acquisition.
/// Uses wttr.in — a completely free weather API with no API key required.
class WeatherService {
  /// Fetches current local temperature (Celsius) and humidity (%) via GPS.
  Future<Map<String, double>> fetchLocalWeather() async {
    // 1. Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    // 2. Check / request GPS permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied. Please allow location access.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions permanently denied. Enable in Settings > Apps > Seri-Helper > Permissions.');
    }

    // 3. Fetch coordinates (low accuracy = fast + battery efficient)
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        distanceFilter: 500,
      ),
    );

    // 4. Query wttr.in — completely free, no API key, reliable JSON output
    final lat = position.latitude.toStringAsFixed(4);
    final lon = position.longitude.toStringAsFixed(4);
    final url = 'https://wttr.in/$lat,$lon?format=j1';

    final response = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': 'SeriHelper/1.0 Flutter'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final current = data['current_condition'][0];
      final double temp     = double.parse(current['temp_C'].toString());
      final double humidity = double.parse(current['humidity'].toString());
      return {'temp': temp, 'humidity': humidity};
    } else {
      throw Exception(
          'Weather unavailable (HTTP ${response.statusCode}). Try again in a few seconds.');
    }
  }
}
