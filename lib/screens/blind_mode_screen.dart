import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as permission;
import 'package:provider/provider.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/location_service.dart';
import '../services/gemini_service.dart';
import '../widgets/ai_response_overlay.dart';
import '../widgets/mini_map.dart';
import '../widgets/destination_selector.dart';
import '../widgets/camera_preview_with_analysis.dart';

class BlindModeScreen extends StatefulWidget {
  final String geminiApiKey;
  
  const BlindModeScreen({
    Key? key,
    required this.geminiApiKey,
  }) : super(key: key);

  @override
  _BlindModeScreenState createState() => _BlindModeScreenState();
}

class _BlindModeScreenState extends State<BlindModeScreen> with WidgetsBindingObserver {
  late final LocationService _locationService;
  late final GeminiService _geminiService;
  late final FlutterTts _flutterTts;
  late final CameraController _cameraController;
  late final StreamSubscription<CompassEvent> _compassSubscription;
  
  bool _isCameraInitialized = false;
  bool _isConnected = true;
  bool _isDarkEnvironment = false;
  bool _isTorchEnabled = false;
  bool _autoTorchEnabled = true;
  bool _forceMiniMapVisible = false;
  bool _hasPermission = false;
  bool _sessionStarted = true;
  bool _isReadingMode = false;
  bool _navigationPaused = false;
  bool _isAssistantMode = false;
  bool _isMicActive = false;
  bool _isGeocodingInProgress = false;
  bool _showDestinationSelector = false;
  
  String _currentMode = "navigation";
  String _overlayText = "";
  String _analysisResult = "";
  String _chatResponse = "";
  String _readingModeResult = "";
  String _destinationInput = "";
  String _destinationQuery = "";
  int _lastSpokenIndex = 0;
  int _lastProcessedTimestamp = 0;
  final int _frameInterval = 5000; // Process a frame every 5 seconds
  
  List<CameraDescription> _cameras = [];
  Timer? _connectivityTimer;
  Timer? _speechTimer;
  Timer? _analysisTimer;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _locationService = LocationService(widget.geminiApiKey);
    _geminiService = GeminiService(widget.geminiApiKey);
    _flutterTts = FlutterTts();
    
    _initializeServices();
    _checkPermissions();
  }
  
  Future<void> _initializeServices() async {
    // Initialize TTS
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(1.5);
    
    // Initialize camera
    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      _cameraController = CameraController(
        _cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );
      
      try {
        await _cameraController.initialize();
        setState(() {
          _isCameraInitialized = true;
        });
      } catch (e) {
        print("Error initializing camera: $e");
      }
    }
    
    // Initialize compass
    if (await FlutterCompass.events != null) {
      _compassSubscription = FlutterCompass.events!.listen((event) {
        // Handle compass events if needed
      });
    }
    
    // Check internet connectivity
    _checkConnectivity();
    _connectivityTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkConnectivity());
    
    // Start location updates
    await _locationService.initialize();
    await _locationService.startLocationUpdates();
    
    // Start session
    _sessionStarted = true;
    _flutterTts.speak("Blind mode activated. Double tap to pause navigation, long press to enter reading mode.");
  }
  
  Future<void> _checkPermissions() async {
    final cameraPermission = await permission.Permission.camera.request();
    final microphonePermission = await permission.Permission.microphone.request();
    final locationPermission = await permission.Permission.location.request();
    
    setState(() {
      _hasPermission = cameraPermission.isGranted && 
                      microphonePermission.isGranted && 
                      locationPermission.isGranted;
    });
  }
  
  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = connectivityResult != ConnectivityResult.none;
    });
    
    if (!_isConnected) {
      _flutterTts.speak("You are not connected to the internet");
    }
  }
  
  void _toggleBlindMode() {
    setState(() {
      _navigationPaused = !_navigationPaused;
      _isAssistantMode = _navigationPaused;
      
      if (_navigationPaused) {
        _flutterTts.stop();
        _currentMode = "assistant";
        _overlayText = "";
        _showDestinationSelector = true;
        _flutterTts.speak("Assistant mode activated. Please select a destination.");
      } else {
        _flutterTts.stop();
        _currentMode = "navigation";
        _overlayText = "";
        _chatResponse = "";
        _showDestinationSelector = false;
        _flutterTts.speak("Assistant mode deactivated. Resuming navigation.");
      }
    });
  }
  
  void _toggleReadingMode() {
    setState(() {
      _isReadingMode = !_isReadingMode;
      
      if (_isReadingMode) {
        _flutterTts.stop();
        _currentMode = "reading";
        _overlayText = "";
        _navigationPaused = true;
        _forceMiniMapVisible = false;
        _flutterTts.speak("Entering reading mode");
        _captureImageForReading();
      } else {
        _flutterTts.stop();
        _currentMode = "navigation";
        _overlayText = "";
        _readingModeResult = "";
        _navigationPaused = false;
        if (_locationService.isNavigating) {
          _forceMiniMapVisible = true;
        }
        _flutterTts.speak("Exiting reading mode");
      }
    });
  }
  
  Future<void> _captureImageForReading() async {
    if (!_isCameraInitialized) return;
    
    try {
      final image = await _cameraController.takePicture();
      final file = File(image.path);
      
      // Process the image for text recognition
      _processTextReading(file);
    } catch (e) {
      print("Error capturing image: $e");
    }
  }
  
  Future<void> _processTextReading(File imageFile) async {
    // Process the image with Gemini API for text recognition
    try {
      final result = await _geminiService.processTextReading(imageFile.path);
      
      setState(() {
        _readingModeResult = result;
      });
      
      _flutterTts.speak(_readingModeResult);
    } catch (e) {
      print("Error processing text reading: $e");
      setState(() {
        _readingModeResult = "Error reading text from image: $e";
      });
    }
  }
  
  void _startImageAnalysis() {
    if (!_isCameraInitialized) return;
    
    _analysisTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_isReadingMode || _navigationPaused) return;
      
      try {
        final image = await _cameraController.takePicture();
        final file = File(image.path);
        
        // Process the image for navigation context
        _processNavigationFrame(file);
      } catch (e) {
        print("Error analyzing image: $e");
      }
    });
  }
  
  Future<void> _processNavigationFrame(File imageFile) async {
    final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
    if (currentTimestamp - _lastProcessedTimestamp < _frameInterval) return;
    
    _lastProcessedTimestamp = currentTimestamp;
    
    // Create navigation context if we're navigating
    NavigationContext? navigationContext;
    if (_locationService.isNavigating) {
      navigationContext = NavigationContext(
        latitude: _locationService.currentLocation?.latitude ?? 0,
        longitude: _locationService.currentLocation?.longitude ?? 0,
        destinationLatitude: _locationService.destination?.latitude ?? 0,
        destinationLongitude: _locationService.destination?.longitude ?? 0,
        destinationName: _locationService.destinationName,
        distanceToDestination: _locationService.distanceToDestination,
        nextDirection: _locationService.navigationInstructions,
      );
    }
    
    // Process the image with Gemini API
    try {
      final result = await _geminiService.processNavigationFrame(
        imageFile.path,
        context: navigationContext,
      );
      
      setState(() {
        // Clear previous results if it's getting too long
        if (_analysisResult.length > 500) {
          _analysisResult = "";
          _lastSpokenIndex = 0;
        }
        
        _analysisResult += " $result";
        
        // Speak the new part
        final newText = _analysisResult.substring(_lastSpokenIndex);
        _flutterTts.speak(newText);
        _lastSpokenIndex = _analysisResult.length;
        
        // Add environment analysis to navigation instructions when navigating
        if (_locationService.isNavigating && _forceMiniMapVisible) {
          // Check if the result contains specific navigation keywords
          if (result.contains("obstacle") || 
              result.contains("hazard") || 
              result.contains("caution") ||
              result.contains("steps") || 
              result.contains("stairs") ||
              result.contains("crossing") || 
              result.contains("pedestrian") ||
              result.contains("traffic")) {
            
            // Update the existing navigation instruction 
            final baseInstruction = _locationService.navigationInstructions;
            final combinedInstruction = "$baseInstruction\nEnvironment: $result";
            _locationService.updateNavigationInstructions(combinedInstruction);
          }
        }
      });
    } catch (e) {
      print("Error processing navigation frame: $e");
    }
  }
  
  void _toggleTorch() {
    if (!_isCameraInitialized) return;
    
    setState(() {
      _autoTorchEnabled = !_autoTorchEnabled;
      
      if (!_autoTorchEnabled && _isTorchEnabled) {
        _isTorchEnabled = false;
      }
    });
  }
  
  void _toggleMiniMap() {
    setState(() {
      _forceMiniMapVisible = !_forceMiniMapVisible;
    });
  }
  
  void _toggleVoiceAssistant() {
    setState(() {
      _isMicActive = !_isMicActive;
      
      if (_isMicActive) {
        _flutterTts.stop();
        _flutterTts.speak("Voice assistant activated. Speak your command.");
        // In a real implementation, this would start speech recognition
      } else {
        _flutterTts.speak("Voice assistant deactivated.");
        // In a real implementation, this would stop speech recognition
      }
    });
  }
  
  void _selectDestination(String destination) {
    setState(() {
      _destinationInput = destination;
    });
  }
  
  Future<void> _navigateToDestination() async {
    if (_destinationInput.isEmpty) {
      _flutterTts.speak("Please enter a destination first.");
      return;
    }
    
    setState(() {
      _destinationQuery = _destinationInput;
      _isGeocodingInProgress = true;
      _showDestinationSelector = false;
    });
    
    try {
      // Get current location
      final currentLocation = _locationService.currentLocation;
      if (currentLocation == null) {
        _flutterTts.speak("Unable to get your current location. Please try again.");
        setState(() {
          _isGeocodingInProgress = false;
        });
        return;
      }
      
      // Geocode the destination
      final destination = await _locationService.geocodeLocation(_destinationInput);
      if (destination == null) {
        _flutterTts.speak("I couldn't find $_destinationInput. Please try a different destination.");
        setState(() {
          _isGeocodingInProgress = false;
        });
        return;
      }
      
      // Start navigation
      _locationService.setDestination(destination);
      _locationService.startNavigation();
      
      // Speak the first instruction
      _flutterTts.speak("Starting navigation to $_destinationInput. The mini map is now visible.");
      
      setState(() {
        _forceMiniMapVisible = true;
        _isGeocodingInProgress = false;
        _navigationPaused = false;
        _currentMode = "navigation";
      });
    } catch (e) {
      print("Error navigating to destination: $e");
      _flutterTts.speak("An error occurred while setting up navigation. Please try again.");
      setState(() {
        _isGeocodingInProgress = false;
      });
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeServices();
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    _compassSubscription.cancel();
    _connectivityTimer?.cancel();
    _speechTimer?.cancel();
    _analysisTimer?.cancel();
    _locationService.dispose();
    _flutterTts.stop();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onDoubleTap: _toggleBlindMode,
        onLongPress: _toggleReadingMode,
        child: Stack(
          children: [
            // Camera preview
            if (_hasPermission && _sessionStarted && !_navigationPaused && !_isReadingMode)
              _buildCameraPreview(),
            
            // Reading mode camera
            if (_hasPermission && _sessionStarted && _isReadingMode)
              _buildReadingModeCamera(),
            
            // AI Response Overlay
            if (_sessionStarted)
              AIResponseOverlay(
                currentMode: _currentMode,
                navigationResponse: _analysisResult,
                chatResponse: _chatResponse,
                readingModeResult: _readingModeResult,
                tts: _flutterTts,
                lastSpokenIndex: _lastSpokenIndex,
                response: _analysisResult,
              ),
            
            // Navigation instructions card
            if (_locationService.isNavigating && !_isReadingMode)
              _buildNavigationCard(),
            
            // Mini map
            if ((_locationService.isNavigating || _forceMiniMapVisible) && !_isReadingMode)
              _buildMiniMap(),
            
            // Loading indicator
            if (_isGeocodingInProgress)
              _buildLoadingIndicator(),
            
            // Destination selector
            if (_showDestinationSelector)
              _buildDestinationSelector(),
            
            // Control buttons
            _buildControlButtons(),
            
            // Navigation icon
            if (_locationService.isNavigating)
              _buildNavigationIcon(),
            
            // Torch indicator
            if (_isTorchEnabled)
              _buildTorchIndicator(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCameraPreview() {
    return CameraPreviewWithAnalysis(
      onImageAnalyzed: _processNavigationFrame,
      onCameraReady: (controller) {
        setState(() {
          _cameraController = controller;
          _isCameraInitialized = true;
        });
      },
      enableTorch: _isTorchEnabled,
      autoTorchEnabled: _autoTorchEnabled,
    );
  }
  
  Widget _buildReadingModeCamera() {
    return CameraPreviewWithAnalysis(
      onImageAnalyzed: (file) {
        _processTextReading(file);
      },
      onCameraReady: (controller) {
        setState(() {
          _cameraController = controller;
          _isCameraInitialized = true;
        });
      },
      enableTorch: _isTorchEnabled,
      autoTorchEnabled: _autoTorchEnabled,
    );
  }
  
  Widget _buildNavigationCard() {
    return Positioned(
      top: 8,
      left: 16,
      right: 16,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Navigating to: ${_locationService.destinationName}",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                "Distance: ${_locationService.distanceToDestination < 1000 
                    ? "${_locationService.distanceToDestination.toInt()} meters" 
                    : "${(_locationService.distanceToDestination / 1000).toStringAsFixed(1)} km"}",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                _locationService.navigationInstructions,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_locationService.progress > 0) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _locationService.progress,
                ),
                Text(
                  "${(_locationService.progress * 100).toInt()}% complete",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMiniMap() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: MiniMap(
        currentLocation: _locationService.currentLocation,
        destination: _locationService.destination,
        destinationName: _locationService.destinationName,
        routePoints: _locationService.routePoints,
        distance: _locationService.distanceToDestination,
        navigationInstructions: _locationService.navigationInstructions,
        progress: _locationService.progress,
      ),
    );
  }
  
  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
  
  Widget _buildDestinationSelector() {
    return DestinationSelector(
      destinationInput: _destinationInput,
      onDestinationChanged: _selectDestination,
      onNavigate: _navigateToDestination,
      onCancel: () {
        setState(() {
          _showDestinationSelector = false;
        });
      },
    );
  }
  
  Widget _buildControlButtons() {
    return Column(
      children: [
        // Top row buttons
        Positioned(
          top: 16,
          left: 16,
          child: Row(
            children: [
              // Torch toggle
              FloatingActionButton(
                onPressed: _toggleTorch,
                backgroundColor: _autoTorchEnabled 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.surface,
                mini: true,
                child: Icon(
                  _autoTorchEnabled ? Icons.flash_on : Icons.flash_off,
                  color: _autoTorchEnabled ? Colors.white : Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              // Map toggle
              FloatingActionButton(
                onPressed: _toggleMiniMap,
                backgroundColor: _forceMiniMapVisible 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.surface,
                mini: true,
                child: Icon(
                  Icons.place,
                  color: _forceMiniMapVisible ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        
        // Top right button
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _toggleVoiceAssistant,
            backgroundColor: _isMicActive 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.surface,
            child: Icon(
              Icons.mic,
              color: _isMicActive ? Colors.white : Colors.grey,
            ),
          ),
        ),
        
        // Bottom left button
        Positioned(
          bottom: 16,
          left: 16,
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                _showDestinationSelector = !_showDestinationSelector;
              });
            },
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.place,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildNavigationIcon() {
    return Positioned(
      bottom: 16,
      child: Icon(
        Icons.navigation,
        size: 64,
        color: Colors.blue,
      ),
    );
  }
  
  Widget _buildTorchIndicator() {
    return Positioned(
      top: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          "Torch ON",
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
} 