import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'gemini_service.dart';

class LocationService extends ChangeNotifier {
  final _locationStreamController = StreamController<Position>.broadcast();
  final _navigationStreamController = StreamController<NavigationUpdate>.broadcast();
  
  Stream<Position> get locationStream => _locationStreamController.stream;
  Stream<NavigationUpdate> get navigationStream => _navigationStreamController.stream;
  
  Position? _currentPosition;
  LatLng? _currentLocation;
  LatLng? _destination;
  double _initialDistance = 0.0;
  double _progress = 0.0;
  String _navigationInstruction = '';
  bool _isNavigating = false;
  Timer? _locationTimer;
  GeminiService? _geminiService;
  
  Position? get currentPosition => _currentPosition;
  LatLng? get currentLocation => _currentLocation;
  LatLng? get destination => _destination;
  double get progress => _progress;
  String get navigationInstruction => _navigationInstruction;
  bool get isNavigating => _isNavigating;
  
  LocationService({GeminiService? geminiService}) {
    _geminiService = geminiService;
    _initializeLocation();
  }
  
  Future<void> _initializeLocation() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return;
      }
      
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      _updateLocation(position);
      
      // Listen to location updates
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen(_updateLocation);
      
    } catch (e) {
      debugPrint('Error initializing location: $e');
    }
  }
  
  void _updateLocation(Position position) {
    _currentPosition = position;
    _currentLocation = LatLng(position.latitude, position.longitude);
    _locationStreamController.add(position);
    
    if (_isNavigating && _destination != null) {
      _updateNavigationInstructions();
    }
    
    notifyListeners();
  }
  
  Future<LatLng> getCurrentLocation() async {
    if (_currentLocation != null) {
      return _currentLocation!;
    }
    
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      _currentPosition = position;
      _currentLocation = LatLng(position.latitude, position.longitude);
      notifyListeners();
      
      return _currentLocation!;
    } catch (e) {
      debugPrint('Error getting current location: $e');
      throw Exception('Failed to get current location: $e');
    }
  }
  
  void startNavigation(LatLng destination, Function(LatLng, String, double) onUpdate) {
    if (_currentLocation == null) {
      throw Exception('Current location is not available');
    }
    
    _destination = destination;
    _isNavigating = true;
    _initialDistance = _calculateDistance(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      destination.latitude,
      destination.longitude,
    );
    _progress = 0.0;
    
    // Generate initial navigation instructions
    _updateNavigationInstructions();
    
    // Set up a timer to update navigation instructions periodically
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isNavigating) {
        _updateNavigationInstructions();
      }
    });
    
    // Notify listeners
    notifyListeners();
    
    // Set up a stream subscription to receive navigation updates
    _navigationStreamController.stream.listen((update) {
      onUpdate(update.location, update.instruction, update.progress);
    });
  }
  
  void stopNavigation() {
    _isNavigating = false;
    _locationTimer?.cancel();
    _navigationInstruction = 'Navigation stopped';
    notifyListeners();
  }
  
  void _updateNavigationInstructions() {
    if (_currentLocation == null || _destination == null) {
      return;
    }
    
    // Calculate distance and bearing
    final distance = _calculateDistance(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      _destination!.latitude,
      _destination!.longitude,
    );
    
    final bearing = _calculateBearing(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      _destination!.latitude,
      _destination!.longitude,
    );
    
    // Generate basic navigation instructions
    String instruction = _generateBasicInstruction(bearing, distance);
    
    // Enhance instructions with Gemini if available
    if (_geminiService != null) {
      _enhanceInstructionsWithGemini(instruction, distance, bearing);
    }
    
    // Update progress
    _progress = 1.0 - (distance / _initialDistance);
    if (_progress < 0.0) _progress = 0.0;
    if (_progress > 1.0) _progress = 1.0;
    
    // Update navigation instruction
    _navigationInstruction = instruction;
    
    // Notify listeners
    notifyListeners();
    
    // Send update through stream
    _navigationStreamController.add(
      NavigationUpdate(
        location: _currentLocation!,
        instruction: instruction,
        progress: _progress,
      ),
    );
  }
  
  Future<void> _enhanceInstructionsWithGemini(String basicInstruction, double distance, double bearing) async {
    try {
      if (_geminiService == null) return;
      
      final context = '''
Current navigation instruction: $basicInstruction
Distance to destination: ${distance.toStringAsFixed(0)} meters
Bearing: ${bearing.toStringAsFixed(0)} degrees
''';
      
      final enhancedInstruction = await _geminiService!.processAssistantQuery(
        'Enhance this navigation instruction to be more helpful for a visually impaired person: $context',
      );
      
      _navigationInstruction = enhancedInstruction;
      notifyListeners();
    } catch (e) {
      debugPrint('Error enhancing instructions with Gemini: $e');
      // Keep the basic instruction if enhancement fails
    }
  }
  
  String _generateBasicInstruction(double bearing, double distance) {
    String direction;
    
    if (bearing >= 337.5 || bearing < 22.5) {
      direction = 'north';
    } else if (bearing >= 22.5 && bearing < 67.5) {
      direction = 'northeast';
    } else if (bearing >= 67.5 && bearing < 112.5) {
      direction = 'east';
    } else if (bearing >= 112.5 && bearing < 157.5) {
      direction = 'southeast';
    } else if (bearing >= 157.5 && bearing < 202.5) {
      direction = 'south';
    } else if (bearing >= 202.5 && bearing < 247.5) {
      direction = 'southwest';
    } else if (bearing >= 247.5 && bearing < 292.5) {
      direction = 'west';
    } else {
      direction = 'northwest';
    }
    
    if (distance < 10) {
      return 'You have arrived at your destination';
    } else if (distance < 50) {
      return 'Your destination is $direction, ${distance.toStringAsFixed(0)} meters away';
    } else if (distance < 100) {
      return 'Continue $direction, ${distance.toStringAsFixed(0)} meters to your destination';
    } else {
      return 'Head $direction, ${distance.toStringAsFixed(0)} meters to your destination';
    }
  }
  
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
  
  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    
    final y = sin(dLon) * cos(lat2 * pi / 180);
    final x = cos(lat1 * pi / 180) * sin(lat2 * pi / 180) -
        sin(lat1 * pi / 180) * cos(lat2 * pi / 180) * cos(dLon);
    
    var bearing = atan2(y, x) * 180 / pi;
    if (bearing < 0) {
      bearing += 360;
    }
    
    return bearing;
  }
  
  @override
  void dispose() {
    _locationStreamController.close();
    _navigationStreamController.close();
    _locationTimer?.cancel();
    super.dispose();
  }
}

class NavigationUpdate {
  final LatLng location;
  final String instruction;
  final double progress;
  
  NavigationUpdate({
    required this.location,
    required this.instruction,
    required this.progress,
  });
} 