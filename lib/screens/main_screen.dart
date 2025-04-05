import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _flutterTts = FlutterTts();
  bool _isSettingsVisible = false;
  bool _isInstructionsVisible = false;

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  void _toggleSettings() {
    setState(() {
      _isSettingsVisible = !_isSettingsVisible;
    });
  }

  void _toggleInstructions() {
    setState(() {
      _isInstructionsVisible = !_isInstructionsVisible;
    });
  }

  void _navigateToBlindMode() {
    Navigator.pushNamed(
      context,
      '/blindMode',
      arguments: 'YOUR_API_KEY', // Replace with your actual API key
    );
  }

  void _navigateToNavigation() {
    Navigator.pushNamed(
      context,
      '/navigation',
      arguments: 'YOUR_API_KEY', // Replace with your actual API key
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EchoNav'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _toggleSettings,
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 32.0),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.only(
                    top: _isSettingsVisible ? 16.0 : 0,
                  ),
                  child: Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: _navigateToBlindMode,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32.0,
                                vertical: 16.0,
                              ),
                            ),
                            child: const Text('Blind Mode'),
                          ),
                          const SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed: _navigateToNavigation,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32.0,
                                vertical: 16.0,
                              ),
                            ),
                            child: const Text('Navigation'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isSettingsVisible)
            Positioned(
              top: 16.0,
              left: 16.0,
              right: 16.0,
              child: Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      SwitchListTile(
                        title: const Text('Voice Guidance'),
                        subtitle: const Text('Enable voice instructions'),
                        value: true,
                        onChanged: (value) {},
                      ),
                      SwitchListTile(
                        title: const Text('Vibration'),
                        subtitle: const Text('Enable vibration feedback'),
                        value: true,
                        onChanged: (value) {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_isInstructionsVisible)
            Positioned(
              bottom: 16.0,
              left: 16.0,
              right: 16.0,
              child: Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Instructions',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      const Text(
                        'Welcome to EchoNav! This app helps visually impaired users navigate their surroundings using voice guidance and camera analysis.',
                      ),
                      const SizedBox(height: 16.0),
                      const Text(
                        'Features:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      const Text('• Blind Mode: Use camera to analyze surroundings'),
                      const Text('• Navigation: Get directions to your destination'),
                      const Text('• Voice Guidance: Hear instructions and descriptions'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleInstructions,
        child: const Icon(Icons.help),
      ),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
} 