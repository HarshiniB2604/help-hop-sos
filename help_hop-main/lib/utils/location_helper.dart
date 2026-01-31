// lib/location_helper.dart
import 'package:geolocator/geolocator.dart';

class LocationHelper {
  static Future<Position?> getLocation() async {
    // Check service
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location service disabled");
      return null;
    }

    // Check permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Location permission denied");
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Location permission permanently denied");
      return null;
    }

    // Get current position
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
