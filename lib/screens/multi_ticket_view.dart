import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/scc_result.dart';
import '../services/scc_service.dart';
import '../widgets/result_card.dart';

class MultiTicketView extends StatefulWidget {
  const MultiTicketView({super.key});

  @override
  State<MultiTicketView> createState() => _MultiTicketViewState();
}

class _MultiTicketViewState extends State<MultiTicketView> {
  final TextEditingController _batchController = TextEditingController();
  final SccService _sccService = SccService();

  bool _isLoading = false;
  int _currentIndex = 0;
  int _totalTickets = 0;
  String _currentProcessingTicket = "";

  final List<SccResult> _results = [];

  Future<void> _processBatch() async {
    final text = _batchController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan tempel atau masukkan daftar tiket terlebih dahulu.")),
      );
      return;
    }

    // Pisahkan tiket per baris atau koma
    final rawLines = text.split(RegExp(r'[\n\r]+'));
    final tickets = <String>[];
    for (var line in rawLines) {
      final clean = line.split(',')[0].trim();
      if (clean.isNotEmpty && !tickets.contains(clean)) {
        tickets.add(clean);
      }
    }

    if (tickets.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _results.clear();
      _totalTickets = tickets.length;
      _currentIndex = 0;
    });

    try {
      for (int i = 0; i < tickets.length; i++) {
        if (!mounted) break;
        final t = tickets[i];

        setState(() {
          _currentIndex = i + 1;
          _currentProcessingTicket = t;
        });

        final res = await _sccService.checkScc(
          ticketId: t,
          autoSpeed: true,
        );

        if (mounted) {
          setState(() {
            _results.add(res);
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentProcessingTicket = "";
        });
      }
    }
  }

  void _copyAllReports() {
    if (_results.isEmpty) return;
    final buffer = StringBuffer();
    for (var r in _results) {
      buffer.writeln(r.toFormattedReport());
      buffer.writeln();
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Semua laporan tiket disalin ke clipboard!")),
    );
  }

  void _shareAllReports() {
    if (_results.isEmpty) return;
    final buffer = StringBuffer();
    for (var r in _results) {
      buffer.writeln(r.toFormattedReport());
      buffer.writeln();
    }
    Share.share(buffer.toString(), subject: "Rekap Laporan SCC (${_results.length} Tiket)");
  }

  @override
  void dispose() {
    _batchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Input Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Pengecekan Multi Tiket (Batch)",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                _batchController.text = "INC53061310\nINC53230635";
                                setState(() {});
                              },
                        child: const Text("Isi Contoh", style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _batchController,
                    maxLines: 5,
                    enabled: !_isLoading,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: "Tempel banyak tiket di sini (satu tiket per baris)\nContoh:\nINC53061310\nINC53230635",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.playlist_play),
                      label: Text(
                        _isLoading
                            ? "Memproses ($_currentIndex/$_totalTickets)..."
                            : "PROSES SEMUA TIKET",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isLoading ? null : _processBatch,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Progres Pengecekan
          if (_isLoading) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.orange.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.orange.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _totalTickets > 0 ? _currentIndex / _totalTickets : 0,
                      backgroundColor: Colors.orange.shade100,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Sedang memproses tiket $_currentIndex dari $_totalTickets: $_currentProcessingTicket",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Daftar Hasil Batch
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Hasil (${_results.length} Tiket)",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      tooltip: "Salin Semua",
                      onPressed: _copyAllReports,
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, size: 20, color: Colors.green),
                      tooltip: "Bagikan Rekap ke WA",
                      onPressed: _shareAllReports,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final r = _results[index];
                final isNormal = r.isNormal;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    leading: Icon(
                      isNormal ? Icons.check_circle : Icons.error,
                      color: isNormal ? Colors.green : Colors.red,
                      size: 28,
                    ),
                    title: Text(
                      r.ticket,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      "${r.status ?? '-'} • ND: ${r.nd ?? '-'}",
                      style: TextStyle(
                        fontSize: 12,
                        color: isNormal ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ResultCard(result: r),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
