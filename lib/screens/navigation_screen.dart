import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';
import '../services/map_service.dart';
import '../widgets/destination_input.dart';
import '../widgets/navigation_map.dart';
import '../widgets/navigation_settings.dart';
import '../widgets/navigation_instructions_list.dart';

class NavigationScreen extends StatefulWidget {
  final String apiKey;

  const NavigationScreen({
    Key? key,
    required this.apiKey,
  }) : super(key: key);

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final _destinationController = TextEditingController();
  final _locationService = LocationService();
  late final _mapService = MapService(widget.apiKey);
  
  bool _isNavigating = false;
  bool _isVoiceEnabled = true;
  bool _isVibrationEnabled = true;
  double _voiceVolume = 0.8;
  bool _isSettingsVisible = false;
  
  LatLng? _currentLocation;
  LatLng? _destination;
  List<LatLng> _routePoints = [];
  String _instruction = 'Enter a destination to start navigation';
  String _distance = '';
  String _duration = '';
  double _progress = 0.0;
  List<NavigationInstruction> _instructions = [];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      final location = await _locationService.getCurrentLocation();
      setState(() {
        _currentLocation = location;
      });
    } catch (e) {
      _showError('Failed to get current location: $e');
    }
  }

  Future<void> _searchDestination() async {
    if (_destinationController.text.isEmpty) {
      _showError('Please enter a destination');
      return;
    }

    try {
      setState(() {
        _instruction = 'Searching for destination...';
      });

      final destination = await _mapService.geocodeLocation(_destinationController.text);
      if (destination == null) {
        _showError('Could not find the destination');
        return;
      }
      
      final route = await _mapService.getDirections(_currentLocation!, destination);
      final routePoints = _mapService.extractRoutePoints(route);
      final instructions = _mapService.getRouteInstructions(routePoints);
      final distance = _mapService.getDistanceText(routePoints);
      final duration = _mapService.getDurationText(routePoints);

      setState(() {
        _destination = destination;
        _routePoints = routePoints;
        _instruction = instructions.first;
        _distance = distance;
        _duration = duration;
        _progress = 0.0;
        _instructions = instructions.asMap().entries.map((entry) {
          return NavigationInstruction(
            instruction: entry.value,
            distance: entry.key == 0 ? distance : '',
            isCurrent: entry.key == 0,
          );
        }).toList();
      });
    } catch (e) {
      _showError('Failed to find destination: $e');
    }
  }

  void _startNavigation() {
    if (_destination == null) {
      _showError('Please search for a destination first');
      return;
    }

    setState(() {
      _isNavigating = true;
    });

    _locationService.startNavigation(
      _destination!,
      (location, instruction, progress) {
        setState(() {
          _currentLocation = location;
          _instruction = instruction;
          _progress = progress;

          // Update instructions list
          _instructions = _instructions.asMap().entries.map((entry) {
            final index = entry.key;
            final instruction = entry.value;
            return NavigationInstruction(
              instruction: instruction.instruction,
              distance: instruction.distance,
              isCompleted: index < _instructions.indexWhere((i) => i.instruction == instruction.instruction),
              isCurrent: index == _instructions.indexWhere((i) => i.instruction == instruction.instruction),
            );
          }).toList();
        });
      },
    );
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
    });

    _locationService.stopNavigation();
  }

  void _toggleVoice() {
    setState(() {
      _isVoiceEnabled = !_isVoiceEnabled;
    });
  }

  void _toggleSettings() {
    setState(() {
      _isSettingsVisible = !_isSettingsVisible;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _toggleSettings,
          ),
        ],
      ),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                NavigationMap(
                  currentLocation: _currentLocation!,
                  destination: _destination,
                  routePoints: _routePoints,
                  instruction: _instruction,
                  distance: _distance,
                  duration: _duration,
                  progress: _progress,
                  isNavigating: _isNavigating,
                  isVoiceEnabled: _isVoiceEnabled,
                  onStartNavigation: _startNavigation,
                  onStopNavigation: _stopNavigation,
                  onToggleVoice: _toggleVoice,
                ),
                if (_isSettingsVisible)
                  Positioned(
                    top: 16.0,
                    left: 16.0,
                    right: 16.0,
                    child: NavigationSettings(
                      isVoiceEnabled: _isVoiceEnabled,
                      isVibrationEnabled: _isVibrationEnabled,
                      voiceVolume: _voiceVolume,
                      onVoiceEnabledChanged: (value) {
                        setState(() {
                          _isVoiceEnabled = value;
                        });
                      },
                      onVibrationEnabledChanged: (value) {
                        setState(() {
                          _isVibrationEnabled = value;
                        });
                      },
                      onVoiceVolumeChanged: (value) {
                        setState(() {
                          _voiceVolume = value;
                        });
                      },
                    ),
                  ),
                if (!_isNavigating)
                  Positioned(
                    top: 16.0,
                    left: 16.0,
                    right: 16.0,
                    child: DestinationInput(
                      controller: _destinationController,
                      onSearch: _searchDestination,
                      isLoading: false,
                    ),
                  ),
                if (_instructions.isNotEmpty)
                  Positioned(
                    bottom: 120.0,
                    left: 16.0,
                    right: 16.0,
                    child: NavigationInstructionsList(
                      instructions: _instructions,
                    ),
                  ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _locationService.dispose();
    super.dispose();
  }
} 