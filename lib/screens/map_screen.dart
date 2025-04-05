import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/location_service.dart';
import '../widgets/ai_response_overlay.dart';

class MapScreen extends StatefulWidget {
  final String geminiApiKey;
  
  const MapScreen({
    Key? key,
    required this.geminiApiKey,
  }) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final LocationService _locationService;
  late final FlutterTts _flutterTts;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isBlindMode = false;
  String _currentMode = "navigation";
  String _navigationResponse = "";
  String _chatResponse = "";
  String _readingModeResult = "";
  int _lastSpokenIndex = 0;
  String _response = "";

  @override
  void initState() {
    super.initState();
    _locationService = LocationService(widget.geminiApiKey);
    _flutterTts = FlutterTts();
    _initializeTts();
    _initializeLocation();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _initializeLocation() async {
    await _locationService.initialize();
    await _locationService.startLocationUpdates();
    
    _locationService.locationStream.listen((locationData) {
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(locationData.latitude!, locationData.longitude!),
            15,
          ),
        );
      }
    });

    _locationService.navigationStream.listen((instruction) {
      setState(() {
        _navigationResponse = instruction;
        _response = instruction;
      });
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: position,
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
      );
    });
    _locationService.setDestination(position);
  }

  void _toggleBlindMode() {
    setState(() {
      _isBlindMode = !_isBlindMode;
    });
  }

  void _startNavigation() {
    _locationService.startNavigation();
  }

  void _stopNavigation() {
    _locationService.stopNavigation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ECHONAV'),
        actions: [
          IconButton(
            icon: Icon(_isBlindMode ? Icons.visibility_off : Icons.visibility),
            onPressed: _toggleBlindMode,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(0, 0),
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers,
            onTap: _onMapTap,
          ),
          if (_isBlindMode)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StreamBuilder<String>(
                        stream: _locationService.navigationStream,
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data ?? 'Tap on the map to set destination',
                            style: Theme.of(context).textTheme.titleMedium,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: _startNavigation,
                            child: const Text('Start Navigation'),
                          ),
                          ElevatedButton(
                            onPressed: _stopNavigation,
                            child: const Text('Stop Navigation'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          AIResponseOverlay(
            currentMode: _currentMode,
            navigationResponse: _navigationResponse,
            chatResponse: _chatResponse,
            readingModeResult: _readingModeResult,
            tts: _flutterTts,
            lastSpokenIndex: _lastSpokenIndex,
            response: _response,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _locationService.dispose();
    _flutterTts.stop();
    super.dispose();
  }
} 