import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MiniMap extends StatelessWidget {
  final LatLng? currentLocation;
  final LatLng? destination;
  final String destinationName;
  final List<LatLng> routePoints;
  final double distance;
  final String navigationInstructions;
  final double progress;

  const MiniMap({
    Key? key,
    this.currentLocation,
    this.destination,
    required this.destinationName,
    required this.routePoints,
    required this.distance,
    required this.navigationInstructions,
    required this.progress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Map
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: currentLocation ?? const LatLng(0, 0),
                zoom: 15,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              markers: _buildMarkers(),
              polylines: _buildPolylines(),
            ),
            
            // Progress indicator
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    
    // Current location marker
    if (currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
    
    // Destination marker
    if (destination != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: destination!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: destinationName),
        ),
      );
    }
    
    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (routePoints.isEmpty) return {};
    
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints,
        color: Colors.blue,
        width: 3,
      ),
    };
  }
} 