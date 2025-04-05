import 'package:flutter/material.dart';

class NavigationInstruction {
  final String instruction;
  final String distance;
  final bool isCompleted;
  final bool isCurrent;

  const NavigationInstruction({
    required this.instruction,
    required this.distance,
    this.isCompleted = false,
    this.isCurrent = false,
  });
}

class NavigationInstructionsList extends StatelessWidget {
  final List<NavigationInstruction> instructions;

  const NavigationInstructionsList({
    Key? key,
    required this.instructions,
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
            'Navigation Instructions',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: instructions.length,
            itemBuilder: (context, index) {
              final instruction = instructions[index];
              return _buildInstructionItem(instruction, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(NavigationInstruction instruction, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildInstructionIcon(instruction),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instruction.instruction,
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: instruction.isCurrent
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: instruction.isCompleted
                        ? Colors.grey
                        : instruction.isCurrent
                            ? Colors.blue
                            : Colors.black,
                  ),
                ),
                if (instruction.distance.isNotEmpty) ...[
                  const SizedBox(height: 4.0),
                  Text(
                    instruction.distance,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionIcon(NavigationInstruction instruction) {
    if (instruction.isCompleted) {
      return const Icon(
        Icons.check_circle,
        color: Colors.green,
      );
    } else if (instruction.isCurrent) {
      return const Icon(
        Icons.navigation,
        color: Colors.blue,
      );
    } else {
      return Icon(
        Icons.circle_outlined,
        color: Colors.grey[400],
      );
    }
  }
} 