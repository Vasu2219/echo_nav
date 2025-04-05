import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CameraPreviewWithAnalysis extends StatefulWidget {
  final Function(File) onImageAnalyzed;
  final Function(CameraController) onCameraReady;
  final bool enableTorch;
  final bool autoTorchEnabled;

  const CameraPreviewWithAnalysis({
    Key? key,
    required this.onImageAnalyzed,
    required this.onCameraReady,
    this.enableTorch = false,
    this.autoTorchEnabled = true,
  }) : super(key: key);

  @override
  _CameraPreviewWithAnalysisState createState() => _CameraPreviewWithAnalysisState();
}

class _CameraPreviewWithAnalysisState extends State<CameraPreviewWithAnalysis> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isInternetAvailable = true;
  Timer? _connectivityTimer;
  Timer? _analysisTimer;
  int _lastProcessedTimestamp = 0;
  final int _frameInterval = 5000; // Process a frame every 5 seconds

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _checkConnectivity();
    _connectivityTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkConnectivity());
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      
      // Set torch mode if needed
      if (widget.enableTorch && widget.autoTorchEnabled) {
        await _controller!.setFlashMode(FlashMode.torch);
      }
      
      // Notify parent that camera is ready
      widget.onCameraReady(_controller!);
      
      // Start image analysis timer
      _startImageAnalysis();
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  void _startImageAnalysis() {
    _analysisTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!_isInternetAvailable) return;
      
      try {
        final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
        if (currentTimestamp - _lastProcessedTimestamp < _frameInterval) return;
        
        _lastProcessedTimestamp = currentTimestamp;
        
        final image = await _controller!.takePicture();
        widget.onImageAnalyzed(File(image.path));
      } catch (e) {
        print('Error analyzing image: $e');
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isInternetAvailable = connectivityResult != ConnectivityResult.none;
    });
  }

  @override
  void didUpdateWidget(CameraPreviewWithAnalysis oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle torch mode changes
    if (widget.enableTorch != oldWidget.enableTorch || 
        widget.autoTorchEnabled != oldWidget.autoTorchEnabled) {
      _updateTorchMode();
    }
  }

  Future<void> _updateTorchMode() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    try {
      if (widget.enableTorch && widget.autoTorchEnabled) {
        await _controller!.setFlashMode(FlashMode.torch);
      } else {
        await _controller!.setFlashMode(FlashMode.off);
      }
    } catch (e) {
      print('Error updating torch mode: $e');
    }
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    _analysisTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return CameraPreview(_controller!);
  }
} 