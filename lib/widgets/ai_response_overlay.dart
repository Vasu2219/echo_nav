import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AIResponseOverlay extends StatefulWidget {
  final String currentMode;
  final String navigationResponse;
  final String chatResponse;
  final String readingModeResult;
  final FlutterTts tts;
  final int lastSpokenIndex;
  final String response;

  const AIResponseOverlay({
    Key? key,
    required this.currentMode,
    required this.navigationResponse,
    required this.chatResponse,
    required this.readingModeResult,
    required this.tts,
    required this.lastSpokenIndex,
    required this.response,
  }) : super(key: key);

  @override
  State<AIResponseOverlay> createState() => _AIResponseOverlayState();
}

class _AIResponseOverlayState extends State<AIResponseOverlay> {
  bool _isConnected = true;
  int _currentIndex = 0;
  String _lastSpokenText = '';
  List<String> _sentences = [];
  Timer? _connectivityTimer;
  Timer? _speechTimer;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.lastSpokenIndex;
    _sentences = widget.response.split('.').where((s) => s.trim().isNotEmpty).toList();
    
    // Check internet connectivity
    _checkConnectivity();
    _connectivityTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkConnectivity());
    
    // Speak sentences periodically
    _speechTimer = Timer.periodic(const Duration(seconds: 8), (_) => _speakNextSentence());
    
    // Speak initial sentence
    if (_sentences.isNotEmpty) {
      _speakSentence(_sentences[_currentIndex]);
    }
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = connectivityResult != ConnectivityResult.none;
    });
    
    if (!_isConnected) {
      widget.tts.speak("You are not connected to the internet");
    }
  }

  void _speakNextSentence() {
    if (!_isConnected || _sentences.isEmpty) return;
    
    _currentIndex = (_currentIndex + 1) % _sentences.length;
    _speakSentence(_sentences[_currentIndex]);
  }

  void _speakSentence(String sentence) {
    final trimmedSentence = sentence.trim();
    if (trimmedSentence.isNotEmpty && trimmedSentence != _lastSpokenText) {
      widget.tts.speak(trimmedSentence);
      setState(() {
        _lastSpokenText = trimmedSentence;
      });
    }
  }

  @override
  void didUpdateWidget(AIResponseOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.response != oldWidget.response) {
      _sentences = widget.response.split('.').where((s) => s.trim().isNotEmpty).toList();
      if (_sentences.isNotEmpty) {
        _speakSentence(_sentences[_currentIndex]);
      }
    }
    
    if (widget.currentMode != oldWidget.currentMode ||
        widget.navigationResponse != oldWidget.navigationResponse ||
        widget.chatResponse != oldWidget.chatResponse ||
        widget.readingModeResult != oldWidget.readingModeResult) {
      _handleModeChange();
    }
  }

  void _handleModeChange() {
    switch (widget.currentMode) {
      case "navigation":
        if (widget.navigationResponse.isNotEmpty) {
          widget.tts.speak(widget.navigationResponse.substring(widget.lastSpokenIndex));
        }
        break;
      case "assistant":
        // Don't automatically speak in assistant mode
        break;
      case "reading":
        // Don't automatically speak in reading mode
        break;
    }
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    _speechTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(16),
        child: _isConnected
            ? _buildContent()
            : _buildNoConnectionMessage(),
      ),
    );
  }

  Widget _buildNoConnectionMessage() {
    return Center(
      child: Text(
        "You are not connected to the internet",
        style: TextStyle(
          color: Colors.red,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModeSpecificContent(),
        ],
      ),
    );
  }

  Widget _buildModeSpecificContent() {
    switch (widget.currentMode) {
      case "reading":
        return _buildTextDisplay(
          "Reading: ${widget.readingModeResult}",
          isItalic: true,
        );
      case "assistant":
        return _buildTextDisplay(
          "Chat: ${widget.chatResponse}",
          isItalic: true,
        );
      case "navigation":
        return _buildTextDisplay(
          widget.navigationResponse,
          isItalic: true,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextDisplay(String text, {bool isItalic = false}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }
} 