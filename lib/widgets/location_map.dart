import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationMap extends StatefulWidget {
  final LatLng currentLocation;
  final LatLng? destination;
  final List<LatLng> routePoints;
  final bool isNavigating;

  const LocationMap({
    Key? key,
    required this.currentLocation,
    this.destination,
    this.routePoints = const [],
    this.isNavigating = false,
  }) : super(key: key);

  @override
  State<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _updateMarkersAndPolylines();
  }

  @override
  void didUpdateWidget(LocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLocation != widget.currentLocation ||
        oldWidget.destination != widget.destination ||
        oldWidget.routePoints != widget.routePoints) {
      _updateMarkersAndPolylines();
    }
  }

  void _updateMarkersAndPolylines() {
    final markers = <Marker>{};
    final polylines = <Polyline>{};

    // Add current location marker
    markers.add(
      Marker(
        markerId: const MarkerId('currentLocation'),
        position: widget.currentLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Current Location'),
      ),
    );

    // Add destination marker if available
    if (widget.destination != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: widget.destination!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
      );
    }

    // Add route polyline if available
    if (widget.routePoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: widget.routePoints,
          color: Colors.blue,
          width: 5,
        ),
      );
    }

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });

    // Update camera position
    _updateCameraPosition();
  }

  void _updateCameraPosition() {
    if (_mapController == null) return;

    if (widget.destination != null) {
      // Calculate bounds to include both current location and destination
      final bounds = LatLngBounds(
        southwest: LatLng(
          min(widget.currentLocation.latitude, widget.destination!.latitude),
          min(widget.currentLocation.longitude, widget.destination!.longitude),
        ),
        northeast: LatLng(
          max(widget.currentLocation.latitude, widget.destination!.latitude),
          max(widget.currentLocation.longitude, widget.destination!.longitude),
        ),
      );

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50.0),
      );
    } else {
      // Just focus on current location
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(widget.currentLocation, 15.0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.currentLocation,
        zoom: 15.0,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        _updateCameraPosition();
      },
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
      compassEnabled: true,
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
} 