import 'package:flutter/material.dart';

class NavigationControls extends StatelessWidget {
  final VoidCallback onStartNavigation;
  final VoidCallback onStopNavigation;
  final VoidCallback onToggleVoice;
  final bool isNavigating;
  final bool isVoiceEnabled;

  const NavigationControls({
    Key? key,
    required this.onStartNavigation,
    required this.onStopNavigation,
    required this.onToggleVoice,
    this.isNavigating = false,
    this.isVoiceEnabled = true,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: isNavigating ? Icons.stop : Icons.play_arrow,
            label: isNavigating ? 'Stop' : 'Start',
            onPressed: isNavigating ? onStopNavigation : onStartNavigation,
            color: isNavigating ? Colors.red : Colors.green,
          ),
          _buildControlButton(
            icon: isVoiceEnabled ? Icons.volume_up : Icons.volume_off,
            label: isVoiceEnabled ? 'Voice On' : 'Voice Off',
            onPressed: onToggleVoice,
            color: isVoiceEnabled ? Colors.blue : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon),
            onPressed: onPressed,
            color: color,
            iconSize: 32.0,
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
} 