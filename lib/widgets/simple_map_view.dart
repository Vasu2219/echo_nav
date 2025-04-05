import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SimpleMapView extends StatelessWidget {
  final LatLng currentLocation;
  final LatLng destination;
  final List<LatLng> routePoints;

  const SimpleMapView({
    Key? key,
    required this.currentLocation,
    required this.destination,
    required this.routePoints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, double.infinity),
      painter: _MapPainter(
        currentLocation: currentLocation,
        destination: destination,
        routePoints: routePoints,
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final LatLng currentLocation;
  final LatLng destination;
  final List<LatLng> routePoints;

  _MapPainter({
    required this.currentLocation,
    required this.destination,
    required this.routePoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // Fixed positions for better visualization
    final sourceX = width * 0.2;
    final sourceY = height * 0.7;
    final destX = width * 0.8;
    final destY = height * 0.3;
    
    // Draw direct line between source and destination
    final dashPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    // Draw dashed line manually
    final dx = destX - sourceX;
    final dy = destY - sourceY;
    final distance = sqrt(dx * dx + dy * dy);
    final dashLength = 10.0;
    final dashCount = (distance / (dashLength * 2)).floor();
    
    for (var i = 0; i < dashCount; i++) {
      final startX = sourceX + (dx * i * 2 * dashLength / distance);
      final startY = sourceY + (dy * i * 2 * dashLength / distance);
      final endX = sourceX + (dx * (i * 2 + 1) * dashLength / distance);
      final endY = sourceY + (dy * (i * 2 + 1) * dashLength / distance);
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        dashPaint,
      );
    }
    
    // Draw direction arrow
    final angle = atan2(destY - sourceY, destX - sourceX);
    final arrowSize = 12.0;
    final arrowX = (sourceX + destX) / 2;
    final arrowY = (sourceY + destY) / 2;
    
    final arrowPoint1X = arrowX + arrowSize * cos(angle - pi / 6);
    final arrowPoint1Y = arrowY + arrowSize * sin(angle - pi / 6);
    final arrowPoint2X = arrowX + arrowSize * cos(angle + pi / 6);
    final arrowPoint2Y = arrowY + arrowSize * sin(angle + pi / 6);
    
    final arrowPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(
      Offset(arrowX, arrowY),
      Offset(arrowPoint1X, arrowPoint1Y),
      arrowPaint,
    );
    
    canvas.drawLine(
      Offset(arrowX, arrowY),
      Offset(arrowPoint2X, arrowPoint2Y),
      arrowPaint,
    );
    
    // Draw current location (blue circle)
    final sourcePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(sourceX, sourceY),
      10,
      sourcePaint,
    );
    
    // Draw destination (red circle)
    final destPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(destX, destY),
      10,
      destPaint,
    );
    
    // Add white background circles for labels
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(sourceX, sourceY),
      22,
      whitePaint,
    );
    
    canvas.drawCircle(
      Offset(destX, destY),
      22,
      whitePaint,
    );
    
    // Draw "S" for source
    canvas.drawCircle(
      Offset(sourceX, sourceY),
      20,
      sourcePaint,
    );
    
    // Draw "D" for destination
    canvas.drawCircle(
      Offset(destX, destY),
      20,
      destPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
} 