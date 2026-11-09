import 'package:flutter/material.dart';
import 'single_ticket_view.dart';
import 'multi_ticket_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: const [
              Icon(Icons.shield, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                "SCC Telkom Checker",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(
                icon: Icon(Icons.confirmation_number_outlined),
                text: "Single Tiket",
              ),
              Tab(
                icon: Icon(Icons.playlist_add_check),
                text: "Multi Tiket (M)",
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Tentang SCC Checker"),
                    content: const Text(
                      "Aplikasi SCC Telkom IndiHome Checker.\n\n"
                      "Fitur:\n"
                      "• Cek SCC tanpa browser\n"
                      "• Auto-Discovery jarak ODP pintar\n"
                      "• Auto-Speed PCRF & noise alami\n"
                      "• Re-probe OLT otomatis\n"
                      "• Mode Batch (Multi Tiket)\n"
                      "• Export & Share ke WhatsApp",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Tutup"),
                      )
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            SingleTicketView(),
            MultiTicketView(),
          ],
        ),
      ),
    );
  }
}
