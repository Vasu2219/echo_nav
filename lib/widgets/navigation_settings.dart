import 'package:flutter/material.dart';

class NavigationSettings extends StatelessWidget {
  final bool isVoiceEnabled;
  final bool isVibrationEnabled;
  final double voiceVolume;
  final ValueChanged<bool> onVoiceEnabledChanged;
  final ValueChanged<bool> onVibrationEnabledChanged;
  final ValueChanged<double> onVoiceVolumeChanged;

  const NavigationSettings({
    Key? key,
    required this.isVoiceEnabled,
    required this.isVibrationEnabled,
    required this.voiceVolume,
    required this.onVoiceEnabledChanged,
    required this.onVibrationEnabledChanged,
    required this.onVoiceVolumeChanged,
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
          const Text(
            'Navigation Settings',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          SwitchListTile(
            title: const Text('Voice Guidance'),
            subtitle: const Text('Enable voice instructions'),
            value: isVoiceEnabled,
            onChanged: onVoiceEnabledChanged,
          ),
          if (isVoiceEnabled) ...[
            const SizedBox(height: 8.0),
            const Text('Voice Volume'),
            Slider(
              value: voiceVolume,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: '${(voiceVolume * 100).round()}%',
              onChanged: onVoiceVolumeChanged,
            ),
          ],
          const SizedBox(height: 8.0),
          SwitchListTile(
            title: const Text('Vibration'),
            subtitle: const Text('Enable vibration feedback'),
            value: isVibrationEnabled,
            onChanged: onVibrationEnabledChanged,
          ),
        ],
      ),
    );
  }
} 