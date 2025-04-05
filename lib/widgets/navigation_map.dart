import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'location_map.dart';
import 'navigation_controls.dart';
import 'navigation_instructions.dart';
import 'navigation_progress.dart';

class NavigationMap extends StatefulWidget {
  final LatLng currentLocation;
  final LatLng? destination;
  final List<LatLng> routePoints;
  final String instruction;
  final String distance;
  final String duration;
  final double progress;
  final bool isNavigating;
  final bool isVoiceEnabled;
  final VoidCallback onStartNavigation;
  final VoidCallback onStopNavigation;
  final VoidCallback onToggleVoice;

  const NavigationMap({
    Key? key,
    required this.currentLocation,
    this.destination,
    this.routePoints = const [],
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.progress,
    this.isNavigating = false,
    this.isVoiceEnabled = true,
    required this.onStartNavigation,
    required this.onStopNavigation,
    required this.onToggleVoice,
  }) : super(key: key);

  @override
  State<NavigationMap> createState() => _NavigationMapState();
}

class _NavigationMapState extends State<NavigationMap> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map
        LocationMap(
          currentLocation: widget.currentLocation,
          destination: widget.destination,
          routePoints: widget.routePoints,
          isNavigating: widget.isNavigating,
        ),
        
        // Navigation Instructions
        Positioned(
          top: 16.0,
          left: 16.0,
          right: 16.0,
          child: NavigationInstructions(
            instruction: widget.instruction,
            distance: widget.distance,
            duration: widget.duration,
            isNavigating: widget.isNavigating,
          ),
        ),
        
        // Navigation Progress
        Positioned(
          bottom: 120.0,
          left: 16.0,
          right: 16.0,
          child: NavigationProgress(
            progress: widget.progress,
            distance: widget.distance,
            duration: widget.duration,
          ),
        ),
        
        // Navigation Controls
        Positioned(
          bottom: 16.0,
          left: 16.0,
          right: 16.0,
          child: NavigationControls(
            onStartNavigation: widget.onStartNavigation,
            onStopNavigation: widget.onStopNavigation,
            onToggleVoice: widget.onToggleVoice,
            isNavigating: widget.isNavigating,
            isVoiceEnabled: widget.isVoiceEnabled,
          ),
        ),
      ],
    );
  }
} 