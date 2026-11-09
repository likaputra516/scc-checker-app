import 'package:flutter/material.dart';

class LogConsole extends StatelessWidget {
  final List<String> logs;

  const LogConsole({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.terminal, color: Colors.greenAccent, size: 16),
              SizedBox(width: 8),
              Text(
                "Proses Pemeriksaan (Live)",
                style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 140),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    log,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFFE0E0E0),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
