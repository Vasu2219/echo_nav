import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _isSoundEnabled = true;
  double _volumeLevel = 0.8;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: _isDarkMode,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                });
              },
            ),
          ),
          ListTile(
            title: const Text('Sound Enabled'),
            trailing: Switch(
              value: _isSoundEnabled,
              onChanged: (value) {
                setState(() {
                  _isSoundEnabled = value;
                });
              },
            ),
          ),
          ListTile(
            title: const Text('Volume Level'),
            subtitle: Slider(
              value: _volumeLevel,
              onChanged: _isSoundEnabled
                  ? (value) {
                      setState(() {
                        _volumeLevel = value;
                      });
                    }
                  : null,
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('About'),
            trailing: const Icon(Icons.info),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'EchoNav',
                applicationVersion: '1.0.0',
                applicationIcon: const FlutterLogo(size: 50),
                children: [
                  const Text(
                    'EchoNav is a navigation app designed to help users navigate their surroundings with audio feedback.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
} 