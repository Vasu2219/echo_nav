import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapService {
  final String apiKey;
  
  MapService(this.apiKey);
  
  /// Geocode an address to get its coordinates
  Future<LatLng?> geocodeLocation(String address) async {
    try {
      // In a real implementation, this would use the Google Maps Geocoding API
      // For now, we'll simulate it with a random location
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Generate a random location (for demo purposes)
      final random = Random();
      final lat = 37.7749 + (random.nextDouble() - 0.5) * 0.1;
      final lng = -122.4194 + (random.nextDouble() - 0.5) * 0.1;
      
      return LatLng(lat, lng);
    } catch (e) {
      debugPrint('Error geocoding location: $e');
      return null;
    }
  }
  
  /// Get directions between two points
  Future<List<LatLng>> getDirections(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      // In a real implementation, this would use the Google Maps Directions API
      // For now, we'll create a simple route with a few points
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Create a simple route with a few points
      return [
        origin,
        LatLng(
          (origin.latitude + destination.latitude) / 2,
          (origin.longitude + destination.longitude) / 2,
        ),
        destination,
      ];
    } catch (e) {
      debugPrint('Error getting directions: $e');
      return [origin, destination];
    }
  }
  
  /// Extract route points from directions result
  List<LatLng> extractRoutePoints(List<LatLng> routePoints) {
    // In a real implementation, this would decode the polyline from the API response
    // For now, we'll just return the provided points
    return routePoints;
  }
  
  /// Get route instructions
  List<String> getRouteInstructions(List<LatLng> routePoints) {
    // In a real implementation, this would extract instructions from the API response
    // For now, we'll return some sample instructions
    return [
      'Head north on Main St',
      'Turn right onto Oak Ave',
      'Continue straight for 200 meters',
      'Your destination is on the right',
    ];
  }
  
  /// Get distance text
  String getDistanceText(List<LatLng> routePoints) {
    // Calculate total distance
    double totalDistance = 0;
    for (int i = 0; i < routePoints.length - 1; i++) {
      totalDistance += _calculateDistance(
        routePoints[i].latitude,
        routePoints[i].longitude,
        routePoints[i + 1].latitude,
        routePoints[i + 1].longitude,
      );
    }
    
    // Format distance
    if (totalDistance < 1000) {
      return '${totalDistance.toInt()} meters';
    } else {
      return '${(totalDistance / 1000).toStringAsFixed(1)} kilometers';
    }
  }
  
  /// Get duration text
  String getDurationText(List<LatLng> routePoints) {
    // Calculate total distance
    double totalDistance = 0;
    for (int i = 0; i < routePoints.length - 1; i++) {
      totalDistance += _calculateDistance(
        routePoints[i].latitude,
        routePoints[i].longitude,
        routePoints[i + 1].latitude,
        routePoints[i + 1].longitude,
      );
    }
    
    // Estimate duration (assuming walking speed of 5 km/h)
    final minutes = (totalDistance / 1000) / 5 * 60;
    
    if (minutes < 1) {
      return 'Less than a minute';
    } else if (minutes < 60) {
      return '${minutes.toInt()} minutes';
    } else {
      final hours = (minutes / 60).floor();
      final remainingMinutes = (minutes % 60).toInt();
      
      if (remainingMinutes == 0) {
        return '$hours hour${hours > 1 ? 's' : ''}';
      } else {
        return '$hours hour${hours > 1 ? 's' : ''} and $remainingMinutes minute${remainingMinutes > 1 ? 's' : ''}';
      }
    }
  }
  
  /// Get estimated remaining time
  String getEstimatedRemainingTime(double distanceMeters) {
    // Average walking speed: 5 km/h = 83.33 meters/minute
    final minutesRemaining = distanceMeters / 83.33;
    
    if (minutesRemaining < 1) {
      return 'less than a minute';
    } else if (minutesRemaining < 60) {
      return '${minutesRemaining.toInt()} minutes';
    } else {
      final hours = (minutesRemaining / 60).floor();
      final remainingMinutes = (minutesRemaining % 60).toInt();
      
      if (remainingMinutes == 0) {
        return '$hours hour${hours > 1 ? 's' : ''}';
      } else {
        return '$hours hour${hours > 1 ? 's' : ''} and $remainingMinutes minute${remainingMinutes > 1 ? 's' : ''}';
      }
    }
  }
  
  /// Get next instruction based on current position
  String getNextInstruction(
    List<LatLng> routePoints,
    LatLng currentLocation,
  ) {
    if (routePoints.isEmpty) {
      return 'Continue on your route';
    }
    
    // Find the closest point on the route
    final closestPointIndex = _findClosestPointOnRoute(currentLocation, routePoints);
    if (closestPointIndex == -1) {
      return 'Continue on your route';
    }
    
    // Get instructions
    final instructions = getRouteInstructions(routePoints);
    
    // If we're close to the end of the route, return the last instruction
    if (closestPointIndex >= routePoints.length - 2) {
      return instructions.last;
    }
    
    // Otherwise, return the next instruction
    return instructions[closestPointIndex];
  }
  
  /// Find the closest point on the route to the current location
  int _findClosestPointOnRoute(LatLng location, List<LatLng> routePoints) {
    if (routePoints.isEmpty) return -1;
    
    int closestPointIndex = -1;
    double minDistance = double.infinity;
    
    for (int i = 0; i < routePoints.length; i++) {
      final point = routePoints[i];
      final distance = _calculateDistance(
        location.latitude,
        location.longitude,
        point.latitude,
        point.longitude,
      );
      
      if (distance < minDistance) {
        minDistance = distance;
        closestPointIndex = i;
      }
    }
    
    return closestPointIndex;
  }
  
  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters
    
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
} 