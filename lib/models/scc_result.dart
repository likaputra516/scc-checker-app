class SccResult {
  final String ticket;
  String? nd;
  String? witel;
  String? olt;
  String? serviceId;
  String? package;
  String? ipAddress;
  bool? isBng;
  String? kualitasJaringan;
  String? kecepatanInternet;
  double? downloadMbps;
  double? uploadMbps;
  double? pingMs;
  double? jitterMs;
  dynamic ontSpeed;
  String? odpName;
  dynamic odpDistanceM;
  bool? odpInsideRadius;
  dynamic odpLat;
  dynamic odpLong;
  Map<String, dynamic>? finalVerdict;
  String? status;
  String? error;
  Map<String, dynamic> raw;

  SccResult({
    required this.ticket,
    this.nd,
    this.witel,
    this.olt,
    this.serviceId,
    this.package,
    this.ipAddress,
    this.isBng,
    this.kualitasJaringan,
    this.kecepatanInternet,
    this.downloadMbps,
    this.uploadMbps,
    this.pingMs,
    this.jitterMs,
    this.ontSpeed,
    this.odpName,
    this.odpDistanceM,
    this.odpInsideRadius,
    this.odpLat,
    this.odpLong,
    this.finalVerdict,
    this.status,
    this.error,
    Map<String, dynamic>? raw,
  }) : raw = raw ?? {};

  bool get isNormal =>
      status != null && status!.contains('NORMAL') && !status!.contains('BELUM');

  bool get isError => status == 'ERROR' || error != null;

  String toFormattedReport() {
    final buffer = StringBuffer();
    final icon = isNormal ? '✅' : (isError ? '❌' : '⚠️');

    buffer.writeln('════════════════════════════════════════════════════════');
    buffer.writeln('  📋  HASIL SCC TELKOM');
    buffer.writeln('════════════════════════════════════════════════════════');
    buffer.writeln('  🎫  Tiket        : $ticket');
    buffer.writeln('  📡  ND           : ${nd ?? "-"}');
    buffer.writeln('  🌍  Witel        : ${witel ?? "-"}');
    buffer.writeln('  🔌  OLT          : ${olt ?? "-"}');
    buffer.writeln('  📦  Paket        : ${package ?? "-"}');
    buffer.writeln('  🌐  IP Publik    : ${ipAddress ?? "-"}');
    buffer.writeln('  🔁  BNG Check    : ${isBng == true ? "✅ Valid" : isBng == false ? "❌ Invalid" : "-"}');
    buffer.writeln('────────────────────────────────────────────────────────');

    final kq = kualitasJaringan ?? '-';
    final ki = kecepatanInternet ?? '(tidak dicek)';
    final kqIcon = kq == 'Layak' ? '✅' : (kq == 'Belum Layak' ? '❌' : '');
    final kiIcon = ki == 'Layak' ? '✅' : (ki == 'Belum Layak' ? '❌' : '⏭️');

    buffer.writeln('  📶  Kualitas Jaringan  : $kqIcon $kq');
    buffer.writeln('  ⚡  Kecepatan Internet : $kiIcon $ki');
    if (downloadMbps != null) {
      buffer.writeln('  ⬇️   Download           : $downloadMbps Mbps');
      buffer.writeln('  ⬆️   Upload             : $uploadMbps Mbps');
      buffer.writeln('  🏓  Ping / Jitter      : $pingMs ms / $jitterMs ms');
    }
    buffer.writeln('  🔧  Speed ONT          : ${ontSpeed ?? "-"}');
    buffer.writeln('────────────────────────────────────────────────────────');

    if (odpName != null || odpDistanceM != null) {
      buffer.writeln('  📍  ODP Name     : ${odpName ?? "-"}');
      buffer.writeln('  📏  Jarak ODP    : ${odpDistanceM != null ? "$odpDistanceM m" : "-"}');
      buffer.writeln('  📌  Dalam Radius : ${odpInsideRadius == true ? "✅ Ya (≤1km)" : odpInsideRadius == false ? "❌ Tidak (>1km)" : "-"}');
      buffer.writeln('────────────────────────────────────────────────────────');
    }

    if (error != null) {
      buffer.writeln('  ⚠️  Error        : $error');
    }

    buffer.writeln('  $icon  STATUS       : ${status ?? "-"}');
    buffer.writeln('════════════════════════════════════════════════════════');
    return buffer.toString();
  }
}
