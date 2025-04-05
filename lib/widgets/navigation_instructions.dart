import 'package:flutter/material.dart';

class NavigationInstructions extends StatelessWidget {
  final String instruction;
  final String distance;
  final String duration;
  final bool isNavigating;

  const NavigationInstructions({
    Key? key,
    required this.instruction,
    required this.distance,
    required this.duration,
    this.isNavigating = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isNavigating ? Icons.navigation : Icons.location_on,
                color: isNavigating ? Colors.blue : Colors.grey,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  instruction,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Distance: $distance',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14.0,
                ),
              ),
              Text(
                'Duration: $duration',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 