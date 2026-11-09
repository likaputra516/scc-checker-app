import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/scc_result.dart';

class ResultCard extends StatelessWidget {
  final SccResult result;

  const ResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isNormal = result.isNormal;
    final statusColor = isNormal ? Colors.green.shade700 : Colors.red.shade700;
    final statusBg = isNormal ? Colors.green.shade50 : Colors.red.shade50;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Tiket & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "NOMOR TIKET",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      Text(
                        result.ticket,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                    border: BorderSide(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isNormal ? Icons.check_circle : Icons.error, color: statusColor, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        isNormal ? "NORMAL" : "BELUM NORMAL",
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Detail Data Pelanggan
            _buildRow("📡 Nomor ND", result.nd ?? "-"),
            _buildRow("🌍 Witel", result.witel ?? "-"),
            _buildRow("🔌 Host OLT", result.olt ?? "-"),
            _buildRow("📦 Paket Internet", result.package ?? "-"),
            _buildRow("🌐 IP Publik", result.ipAddress ?? "-"),
            _buildRow(
              "🔁 Status BNG",
              result.isBng == true ? "Valid ✅" : result.isBng == false ? "Invalid ❌" : "-",
            ),

            const Divider(height: 24),

            // Kualitas Jaringan & Kecepatan
            _buildRow(
              "📶 Kualitas Jaringan",
              result.kualitasJaringan != null
                  ? "${result.kualitasJaringan == 'Layak' ? '✅' : '❌'} ${result.kualitasJaringan}"
                  : "-",
            ),
            _buildRow(
              "⚡ Kecepatan Internet",
              result.kecepatanInternet != null
                  ? "${result.kecepatanInternet == 'Layak' ? '✅' : '❌'} ${result.kecepatanInternet}"
                  : "-",
            ),
            if (result.downloadMbps != null)
              _buildRow(
                "⬇️ Download / ⬆️ Upload",
                "${result.downloadMbps} Mbps / ${result.uploadMbps} Mbps",
              ),
            if (result.pingMs != null)
              _buildRow(
                "🏓 Ping / Jitter",
                "${result.pingMs} ms / ${result.jitterMs} ms",
              ),

            // ODP Info
            if (result.odpName != null || result.odpDistanceM != null) ...[
              const Divider(height: 24),
              _buildRow("📍 ODP Terdekat", result.odpName ?? "-"),
              _buildRow(
                "📏 Jarak ke ODP",
                result.odpDistanceM != null ? "${result.odpDistanceM} m" : "-",
              ),
              _buildRow(
                "📌 Dalam Radius (≤1km)",
                result.odpInsideRadius == true ? "Ya ✅" : result.odpInsideRadius == false ? "Tidak ❌" : "-",
              ),
            ],

            if (result.error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "⚠️ ${result.error}",
                  style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action Buttons: Salin & Share
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text("Salin Teks"),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: result.toFormattedReport()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Laporan berhasil disalin ke clipboard!"),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text("Share WA"),
                    onPressed: () {
                      Share.share(result.toFormattedReport(), subject: "Laporan SCC ${result.ticket}");
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
