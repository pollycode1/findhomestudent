import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static const String _placesApiKey = 'YOUR_GOOGLE_PLACES_API_KEY'; // ต้องใส่ API Key

  // ขอสิทธิ์เข้าถึงตำแหน่ง
  Future<bool> requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }
  // ดึงตำแหน่งปัจจุบัน
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current position: $e');
      }
      return null;
    }
  }

  // แปลงพิกัดเป็นที่อยู่
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        return '${placemark.street}, ${placemark.subLocality}, ${placemark.locality}, ${placemark.administrativeArea} ${placemark.postalCode}';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting address from coordinates: $e');
      }
    }
    return 'ไม่สามารถระบุที่อยู่ได้';
  }

  // แปลงที่อยู่เป็นพิกัด
  Future<Position?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        Location location = locations.first;
        return Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting coordinates from address: $e');
      }
    }
    return null;
  }

  // ค้นหาสถานที่ใกล้เคียง
  Future<List<Map<String, dynamic>>> getNearbyPlaces(
    double latitude,
    double longitude, {
    int radius = 1000,
    String type = 'establishment',
  }) async {
    try {
      final String url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=$latitude,$longitude'
          '&radius=$radius'
          '&type=$type'
          '&key=$_placesApiKey';

      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return List<Map<String, dynamic>>.from(data['results']);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting nearby places: $e');
      }
    }
    return [];
  }  // แยกข้อมูลจาก Google Maps URL ที่แชร์
  Map<String, dynamic>? parseSharedMapUrl(String url) {
    try {
      if (kDebugMode) {
        debugPrint('Parsing URL: $url');
      }
      
      // ลบ whitespace และ newlines
      url = url.trim().replaceAll('\n', '').replaceAll('\r', '');
      if (kDebugMode) {
        debugPrint('Cleaned URL: $url');
      }
      
      // Pattern 1: @latitude,longitude,zoom format (standard Google Maps)
      RegExp regExp = RegExp(r'@(-?\d+\.?\d*),(-?\d+\.?\d*),?(\d+\.?\d*)?z?');
      Match? match = regExp.firstMatch(url);
        if (match != null) {
        double latitude = double.parse(match.group(1)!);
        double longitude = double.parse(match.group(2)!);
        if (kDebugMode) {
          debugPrint('Found coordinates (pattern 1): $latitude, $longitude');
        }
        
        return {
          'latitude': latitude,
          'longitude': longitude,
        };
      }

      // Pattern 2: ll=latitude,longitude format
      regExp = RegExp(r'll=(-?\d+\.?\d*),(-?\d+\.?\d*)');
      match = regExp.firstMatch(url);
        if (match != null) {
        double latitude = double.parse(match.group(1)!);
        double longitude = double.parse(match.group(2)!);
        if (kDebugMode) {
          debugPrint('Found coordinates (pattern 2): $latitude, $longitude');
        }
        
        return {
          'latitude': latitude,
          'longitude': longitude,
        };
      }

      // Pattern 3: q=latitude,longitude format
      regExp = RegExp(r'q=(-?\d+\.?\d*),(-?\d+\.?\d*)');
      match = regExp.firstMatch(url);
        if (match != null) {
        double latitude = double.parse(match.group(1)!);
        double longitude = double.parse(match.group(2)!);
        if (kDebugMode) {
          debugPrint('Found coordinates (pattern 3): $latitude, $longitude');
        }
        
        return {
          'latitude': latitude,
          'longitude': longitude,
        };
      }      // Pattern 4: center=latitude,longitude format
      regExp = RegExp(r'center=(-?\d+\.?\d*),(-?\d+\.?\d*)');
      match = regExp.firstMatch(url);
        if (match != null) {
        double latitude = double.parse(match.group(1)!);
        double longitude = double.parse(match.group(2)!);
        if (kDebugMode) {
          debugPrint('Found coordinates (pattern 4): $latitude, $longitude');
        }
        
        return {
          'latitude': latitude,
          'longitude': longitude,
        };
      }

      // Pattern 5: Line specific format - check for any coordinate pairs
      regExp = RegExp(r'(-?\d{1,3}\.\d{4,}),(-?\d{1,3}\.\d{4,})');
      match = regExp.firstMatch(url);
        if (match != null) {
        double latitude = double.parse(match.group(1)!);
        double longitude = double.parse(match.group(2)!);
        if (kDebugMode) {
          debugPrint('Found coordinates (pattern 5): $latitude, $longitude');
        }
        
        // ตรวจสอบว่าพิกัดอยู่ในช่วงที่สมเหตุสมผล
        if (latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180) {
          return {
            'latitude': latitude,
            'longitude': longitude,
          };
        }
      }

      // Pattern 6: place_id format
      regExp = RegExp(r'place_id[=:]([a-zA-Z0-9_-]+)');
      match = regExp.firstMatch(url);
        if (match != null) {
        String placeId = match.group(1)!;
        if (kDebugMode) {
          debugPrint('Found place ID: $placeId');
        }
        return {
          'place_id': placeId,
        };
      }

      // Pattern 7: Plus codes
      regExp = RegExp(r'plus\.codes/([A-Z0-9+]+)');
      match = regExp.firstMatch(url);
        if (match != null) {
        String plusCode = match.group(1)!;
        if (kDebugMode) {
          debugPrint('Found plus code: $plusCode');
        }
        return {
          'plus_code': plusCode,
        };
      }
      
      if (kDebugMode) {
        debugPrint('No coordinates found in URL');
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error parsing shared map URL: $e');
      }
    }
    return null;
  }

  // ดึงรายละเอียดจาก Place ID
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      final String url = 'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$placeId'
          '&key=$_placesApiKey';

      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['result'];
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting place details: $e');
      }
    }
    return null;
  }

  // คำนวณระยะทางระหว่างสองจุด
  double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // สร้าง URL สำหรับเปิดใน Google Maps
  String createGoogleMapsUrl(double latitude, double longitude, {String? label}) {
    if (label != null) {
      return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude&query_place_id=$label';
    }
    return 'https://www.google.com/maps/@$latitude,$longitude,17z';
  }
}
