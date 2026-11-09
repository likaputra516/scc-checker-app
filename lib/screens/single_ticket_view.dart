import 'package:flutter/material.dart';
import '../models/scc_result.dart';
import '../services/scc_service.dart';
import '../widgets/log_console.dart';
import '../widgets/result_card.dart';

class SingleTicketView extends StatefulWidget {
  const SingleTicketView({super.key});

  @override
  State<SingleTicketView> createState() => _SingleTicketViewState();
}

class _SingleTicketViewState extends State<SingleTicketView> {
  final TextEditingController _ticketController = TextEditingController();
  final SccService _sccService = SccService();

  bool _autoSpeed = true;
  bool _isLoading = false;
  final List<String> _logs = [];
  SccResult? _result;

  Future<void> _runCheck() async {
    final ticket = _ticketController.text.trim();
    if (ticket.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan masukkan nomor tiket terlebih dahulu (contoh: INC53061310)")),
      );
      return;
    }

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _logs.clear();
      _result = null;
    });

    try {
      final res = await _sccService.checkScc(
        ticketId: ticket,
        autoSpeed: _autoSpeed,
        onLog: (msg) {
          if (mounted) {
            setState(() {
              _logs.add(msg);
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _result = res;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _ticketController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Input Form
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pengecekan Tiket Tunggal",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ticketController,
                    textCapitalization: TextCapitalization.characters,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: "Nomor Tiket (INC / IN)",
                      hintText: "Contoh: INC53061310",
                      prefixIcon: const Icon(Icons.confirmation_number_outlined),
                      suffixIcon: _ticketController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _ticketController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _runCheck(),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Auto-Speed & Jarak Layak", style: TextStyle(fontSize: 14)),
                    subtitle: const Text(
                      "Otomatis hitung kecepatan dari paket & jarak ODP valid",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    value: _autoSpeed,
                    activeColor: Colors.red.shade700,
                    onChanged: _isLoading
                        ? null
                        : (val) {
                            setState(() {
                              _autoSpeed = val;
                            });
                          },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : _runCheck,
                      child: _isLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                ),
                                SizedBox(width: 12),
                                Text("Sedang Memeriksa SCC..."),
                              ],
                            )
                          : const Text(
                              "CEK SCC SEKARANG",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Log console
          if (_logs.isNotEmpty) LogConsole(logs: _logs),

          // Hasil pemeriksaan
          if (_result != null) ...[
            const SizedBox(height: 16),
            ResultCard(result: _result!),
          ],
        ],
      ),
    );
  }
}
