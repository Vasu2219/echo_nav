import 'package:flutter/material.dart';

class DestinationSelector extends StatelessWidget {
  final String destinationInput;
  final Function(String) onDestinationChanged;
  final VoidCallback onNavigate;
  final VoidCallback onCancel;

  const DestinationSelector({
    Key? key,
    required this.destinationInput,
    required this.onDestinationChanged,
    required this.onNavigate,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(16),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Select Destination",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Enter destination",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: onDestinationChanged,
                    controller: TextEditingController(text: destinationInput),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => onDestinationChanged("hospital"),
                        child: const Text("Hospital"),
                      ),
                      ElevatedButton(
                        onPressed: () => onDestinationChanged("grocery store"),
                        child: const Text("Grocery"),
                      ),
                      ElevatedButton(
                        onPressed: () => onDestinationChanged("pharmacy"),
                        child: const Text("Pharmacy"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: onCancel,
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: onNavigate,
                        child: const Text("Navigate"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 