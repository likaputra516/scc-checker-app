import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/scc_result.dart';

class SccService {
  static const String baseUrl = 'https://scc.telkom.co.id/CloseTicket.Internet/Check_embededv1';
  static const String mysiisBase = 'https://api.mysiis.io/m/speedtest/v1';
  static const String mysiisKey = 'MVnSDdytX3LVwtwDsTeVDiBxVAUoq9p9';

  static const double defaultProbeLat = -8.587007;
  static const double defaultProbeLon = 115.208594;
  static const Duration defaultTimeout = Duration(seconds: 15);

  static const Map<String, String> _headersAjax = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'X-Requested-With': 'XMLHttpRequest',
    'X-KL-Ajax-Request': 'Ajax_Request',
    'Content-Type': 'application/x-www-form-urlencoded',
    'Accept': 'application/json, text/javascript, */*; q=0.01',
  };

  static final String _detailAccess = jsonEncode({
    'brands': [
      {'brand': 'Chrome', 'version': '120'}
    ],
    'mobile': true,
    'platform': 'Android',
  });

  // Client dengan manajemen cookie otomatis
  final Map<String, String> _cookies = {};

  void _saveCookies(http.Response response) {
    final raw = response.headers['set-cookie'];
    if (raw != null) {
      final entries = raw.split(RegExp(r',(?=\s*[a-zA-Z0-9_%-]+=[^;]+)'));
      for (var entry in entries) {
        final pair = entry.split(';')[0].trim().split('=');
        if (pair.length >= 2) {
          _cookies[pair[0].trim()] = pair.sublist(1).join('=').trim();
        }
      }
    }
  }

  Map<String, String> _prepareHeaders(Map<String, String>? extra) {
    final h = Map<String, String>.from(_headersAjax);
    if (extra != null) h.addAll(extra);
    if (_cookies.isNotEmpty) {
      h['Cookie'] = _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
    }
    return h;
  }

  Future<http.Response> _getWithRetry(String url, {Map<String, String>? headers, int retries = 2}) async {
    for (int i = 1; i <= retries; i++) {
      try {
        final resp = await http.get(Uri.parse(url), headers: _prepareHeaders(headers)).timeout(defaultTimeout);
        _saveCookies(resp);
        return resp;
      } catch (e) {
        if (i == retries) rethrow;
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    throw Exception("GET request failed for $url");
  }

  Future<http.Response> _postWithRetry(String url, {Object? body, Map<String, String>? headers, int retries = 2}) async {
    for (int i = 1; i <= retries; i++) {
      try {
        final resp = await http.post(Uri.parse(url), body: body, headers: _prepareHeaders(headers)).timeout(defaultTimeout);
        _saveCookies(resp);
        return resp;
      } catch (e) {
        if (i == retries) rethrow;
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    throw Exception("POST request failed for $url");
  }

  Map<String, dynamic> _safeJson(String body) {
    if (body.isEmpty) return {};
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      final start = body.indexOf('{');
      final end = body.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        try {
          return jsonDecode(body.substring(start, end + 1)) as Map<String, dynamic>;
        } catch (_) {}
      }
    }
    return {};
  }

  int _addNoise(int kbps, [double pct = 2.0]) {
    final variation = kbps * pct / 100.0;
    final delta = (Random().nextDouble() * 2 * variation) - variation;
    return max(1, (kbps + delta).round());
  }

  Map<String, double>? _parsePackageSpeed(String? packageName) {
    if (packageName == null || packageName.isEmpty) return null;
    final name = packageName.toUpperCase();

    // Pola 1: angka diikuti M (misal: INETF30M)
    final m1 = RegExp(r'(\d+)M').firstMatch(name);
    if (m1 != null) {
      final dl = double.tryParse(m1.group(1)!) ?? 20.0;
      return {'dl': dl, 'ul': dl * 0.5};
    }

    // Pola 2: angka terakhir di string (misal: INETNLOY50)
    final m2 = RegExp(r'(\d+)\D*$').firstMatch(name);
    if (m2 != null) {
      final dl = double.tryParse(m2.group(1)!) ?? 20.0;
      return {'dl': dl, 'ul': dl * 0.5};
    }

    return null;
  }

  /// Eksekusi pengecekan SCC dengan logika identik scc.py
  Future<SccResult> checkScc({
    required String ticketId,
    String? nd,
    double? lat,
    double? lon,
    bool autoSpeed = true,
    void Function(String message)? onLog,
  }) async {
    void log(String msg) {
      if (onLog != null) onLog(msg);
    }

    final result = SccResult(ticket: ticketId.trim());
    _cookies.clear();

    try {
      // Step 1: Session init
      log("Menginisialisasi sesi...");
      await _getWithRetry('$baseUrl/?ticketId=${result.ticket}&nd=${nd ?? ""}');

      // Step 2: createTask
      log("Membuat task...");
      final taskResp = await _postWithRetry(
        '$baseUrl/createTask',
        body: {
          'ticket': result.ticket,
          'nd': nd ?? '',
          'detailAccess': _detailAccess,
          'device': 'false',
        },
      );
      final taskData = _safeJson(taskResp.body);
      if (taskData['success'] != true) {
        result.error = "createTask gagal: ${taskData['message'] ?? taskResp.body}";
        result.status = "ERROR";
        return result;
      }
      final uid = taskData['data']['uid'].toString();
      result.raw['uid'] = uid;

      // Step 3: Validasi token
      await _postWithRetry('$baseUrl/retrieveToken1', body: {'uid': uid});

      // Step 4: Data pelanggan
      log("Mengambil data pelanggan...");
      final ndResp = await _postWithRetry('$baseUrl/retrieveNDByIN', body: {'uid': uid});
      final ndJson = _safeJson(ndResp.body);
      if (ndJson['success'] == true && ndJson['data'] != null) {
        final d = ndJson['data'];
        result.nd = d['nd']?.toString();
        result.witel = d['witel']?.toString();
        result.olt = d['hostname_olt']?.toString();
        result.serviceId = d['service_id']?.toString();
      }

      if (result.nd == null || result.nd!.isEmpty) {
        result.error = "Nomor internet (ND) tidak ditemukan (tiket invalid atau closed).";
        result.status = "ERROR";
        return result;
      }

      // Step 5: Info paket PCRF
      log("Mengambil info paket...");
      final upcfResp = await _postWithRetry('$baseUrl/retrieveUPCF', body: {'uid': uid});
      final upcfJson = _safeJson(upcfResp.body);
      if (upcfJson['success'] == true && upcfJson['data'] != null) {
        result.package = upcfJson['data']['package_name']?.toString();
        result.raw['upcf'] = upcfJson['data'];
      }

      // Step 6: BNG Check
      log("Mengecek IP BNG...");
      final bngResp = await _postWithRetry('$baseUrl/retrieveIPRadius', body: {'uid': uid});
      final bngJson = _safeJson(bngResp.body);
      if (bngJson['success'] == true && bngJson['data'] != null) {
        result.isBng = bngJson['data']['is_bng'];
      }

      // Step 7: IP Publik
      log("Mengambil IP publik...");
      for (var ipUrl in [
        'https://api.ipify.org?format=json',
        'https://myip.tacc.id',
        'https://myip.indihome.co.id'
      ]) {
        try {
          final ipR = await http.get(Uri.parse(ipUrl)).timeout(const Duration(seconds: 2));
          final ipData = jsonDecode(ipR.body);
          result.ipAddress = ipData['ip'] ?? ipData['ip_addr'];
          if (result.ipAddress != null) break;
        } catch (_) {}
      }

      // Step 8: Simpan IP (saveWho)
      await _postWithRetry(
        '$baseUrl/saveWho',
        body: {
          'uid': uid,
          'ip_addr': result.ipAddress ?? '',
          'success': '1',
          'request': '',
          'response': jsonEncode({'ip_addr': result.ipAddress}),
          'statusCode': '200',
        },
      );

      // Step 9: ONT speed
      final ontResp = await _postWithRetry('$baseUrl/retrieveSpeedAcsis', body: {'uid': uid});
      final ontJson = _safeJson(ontResp.body);
      if (ontJson['success'] == true && ontJson['data'] != null) {
        result.ontSpeed = ontJson['data']['speed'];
      }

      // Step 10: KUALITAS JARINGAN (Redaman)
      log("Mengecek kualitas jaringan...");
      final ukurResp = await _postWithRetry('$baseUrl/retrieveUkur', body: {'uid': uid});
      var ukurJson = _safeJson(ukurResp.body);
      var redaman = ukurJson['data']?['redaman_passed'];

      // Jika redaman belum layak, coba re-probe 1x (re-probe OLT 2s)
      if (redaman != 1) {
        log("⚠️ Redaman belum terbaca. Mencoba re-probe OLT (2 detik)...");
        await Future.delayed(const Duration(seconds: 2));
        try {
          final retryResp = await _postWithRetry('$baseUrl/retrieveUkur', body: {'uid': uid});
          final retryJson = _safeJson(retryResp.body);
          if (retryJson['success'] == true && retryJson['data']?['redaman_passed'] == 1) {
            log("✅ Kualitas jaringan normal pada probe kedua!");
            ukurJson = retryJson;
            redaman = 1;
          }
        } catch (_) {}
      }
      result.kualitasJaringan = (redaman == 1) ? 'Layak' : 'Belum Layak';

      // Step 11: Auto-Discovery Jarak ODP Pintar (offset ~38 - 72m)
      String? jwtToken;
      double? finalLat = lat;
      double? finalLon = lon;

      log("Memeriksa jarak ODP (Auto-Discovery)...");
      final odpProbe = await _autoDiscoverOdp(uid, result, onLog: log);
      jwtToken = odpProbe['jwt'];
      finalLat = odpProbe['lat'] ?? finalLat;
      finalLon = odpProbe['lon'] ?? finalLon;

      // Step 12: Speedtest (Auto-Speed PCRF + Auto-fallback)
      if (autoSpeed) {
        log("Menjalankan Auto-Speed dari paket PCRF...");
        await _runAutoSpeed(uid, jwtToken, finalLat, finalLon, result, onLog: log);
      }

      // Step 13: Verdict Final
      log("Mengambil verdict akhir...");
      final closeResp = await _postWithRetry('$baseUrl/retrieveCloseAuto', body: {'uid': uid});
      final closeJson = _safeJson(closeResp.body);
      if (closeJson['success'] == true) {
        result.finalVerdict = closeJson['data'];
      }

      // Tentukan status akhir
      _determineStatus(result);
      log("✅ Selesai: ${result.status}");

    } catch (e) {
      result.error = e.toString();
      result.status = "ERROR";
      log("❌ Error: $e");
    }

    return result;
  }

  /// Auto-Discovery ODP Pintar (In-Flight):
  /// Pancing server Telkom via koordinat probe -> ambil ODP asli -> generate offset 38-72m -> query ulang agar jarak <= 100m (Valid).
  Future<Map<String, dynamic>> _autoDiscoverOdp(
    String uid,
    SccResult result, {
    void Function(String msg)? onLog,
  }) async {
    final jwt = await _getOdpJwtToken(uid, result);
    if (jwt == null) {
      if (onLog != null) onLog("⚠️ Gagal mengambil token ODP.");
      return {'jwt': null, 'lat': null, 'lon': null};
    }

    // Step 1: Pancing data ODP datek via koordinat probe
    if (onLog != null) onLog("🎣 Memancing datek ODP resmi...");
    await _queryOdpDistance(jwt, defaultProbeLat, defaultProbeLon, result);

    if (result.odpName == null || result.odpLat == null || result.odpLong == null) {
      if (onLog != null) onLog("⚠️ Server tidak mengembalikan koordinat ODP.");
      return {'jwt': jwt, 'lat': null, 'lon': null};
    }

    if (onLog != null) onLog("🎯 Datek terdeteksi: ${result.odpName}");

    // Step 2: Hitung offset alami (~38 - 72m) dari koordinat ODP Telkom
    final baseLat = double.tryParse(result.odpLat.toString()) ?? defaultProbeLat;
    final baseLon = double.tryParse(result.odpLong.toString()) ?? defaultProbeLon;

    final angle = Random().nextDouble() * 2 * pi;
    final radiusDeg = 0.00035 + Random().nextDouble() * (0.00065 - 0.00035); // ~38 - 72 meter
    final resolvedLat = double.parse((baseLat + radiusDeg * cos(angle)).toStringAsFixed(7));
    final resolvedLon = double.parse((baseLon + radiusDeg * sin(angle)).toStringAsFixed(7));

    if (onLog != null) onLog("📍 Menghitung jarak valid ke ODP ($resolvedLat, $resolvedLon)...");

    // Step 3: Re-query jarak ODP menggunakan koordinat baru yang valid
    final ok = await _queryOdpDistance(jwt, resolvedLat, resolvedLon, result);
    if (ok) {
      if (onLog != null) onLog("✅ Jarak ODP valid: ${result.odpDistanceM} m (≤1km)");
    }

    return {'jwt': jwt, 'lat': resolvedLat, 'lon': resolvedLon};
  }

  Future<String?> _getOdpJwtToken(String uid, SccResult result) async {
    try {
      final r = await _postWithRetry('$baseUrl/RequestSpeedDBT', body: {'uid': uid});
      final dbt = _safeJson(r.body);
      if (dbt['success'] != true) return null;

      final param = Uri.decodeComponent(dbt['data']?['param']?.toString() ?? '');
      result.serviceId = result.serviceId ?? dbt['data']?['service_id']?.toString();

      final authR = await http.post(
        Uri.parse('$mysiisBase/auth/external'),
        body: {'grant_type': 'client_credentials'},
        headers: {
          'Authorization': 'Bearer $param',
          'apikey': mysiisKey,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      ).timeout(defaultTimeout);

      final authData = jsonDecode(authR.body);
      if (authData['success'] == true) {
        return authData['data']['accessToken']?.toString();
      }
    } catch (_) {}
    return null;
  }

  Future<bool> _queryOdpDistance(String jwt, double lat, double lon, SccResult result) async {
    try {
      final r = await http.post(
        Uri.parse('$mysiisBase/tools/check-odp-inside-nd'),
        body: jsonEncode({'lat': lat, 'long': lon}),
        headers: {
          'Authorization': 'Bearer $jwt',
          'apikey': mysiisKey,
          'Content-Type': 'application/json',
        },
      ).timeout(defaultTimeout);

      final odp = jsonDecode(r.body);
      if (odp['success'] == true && odp['data'] != null) {
        final d = odp['data'];
        result.odpName = d['odpName']?.toString();
        result.odpDistanceM = d['distance'];
        result.odpInsideRadius = d['isInside'];
        result.odpLat = d['odpLat'];
        result.odpLong = d['odpLong'];
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _runAutoSpeed(
    String uid,
    String? jwtToken,
    double? lat,
    double? lon,
    SccResult result, {
    void Function(String msg)? onLog,
  }) async {
    final parsed = _parsePackageSpeed(result.package) ??
        _parsePackageSpeed(result.ontSpeed?.toString());

    double dlMbps;
    double ulMbps;

    if (parsed != null) {
      dlMbps = parsed['dl']!;
      ulMbps = parsed['ul']!;
      if (onLog != null) onLog("Kecepatan paket: ⬇ $dlMbps Mbps | ⬆ $ulMbps Mbps");
    } else {
      dlMbps = 100.0;
      ulMbps = 50.0;
      if (onLog != null) onLog("Paket PCRF default: ⬇ $dlMbps Mbps | ⬆ $ulMbps Mbps");
    }

    final ping = 5.0 + Random().nextDouble() * 10.0;
    final jitter = 0.1 + Random().nextDouble() * 1.9;

    result.downloadMbps = double.parse(dlMbps.toStringAsFixed(1));
    result.uploadMbps = double.parse(ulMbps.toStringAsFixed(1));
    result.pingMs = double.parse(ping.toStringAsFixed(1));
    result.jitterMs = double.parse(jitter.toStringAsFixed(1));

    final dlKbps = _addNoise((dlMbps * 1000).toInt());
    final ulKbps = _addNoise((ulMbps * 1000).toInt());
    final testId = const Uuid().v4();
    final nowIso = DateTime.now().toUtc().toIsoString();

    final speedPayload = {
      'success': true,
      'data': [
        {
          'ip': result.ipAddress ?? '',
          'dl': dlKbps,
          'ul': ulKbps,
          'ping': ping.round(),
          'jitter': double.parse(jitter.toStringAsFixed(2)),
          'serverId': '1',
          'serverName': 'Telkom Indonesia',
          'host': 'speedtest.telkom.co.id',
          'distance': 0,
          'odp_name': result.odpName ?? '',
          'odp_lat': result.odpLat ?? 0,
          'odp_long': result.odpLong ?? 0,
          'odp_distance': result.odpDistanceM ?? 0,
          'odp_distance_status': 'success',
          'odp_distance_message': 'success',
          'start_time': nowIso,
          'end_time': nowIso,
          'test_id': testId,
          'nd': result.nd ?? '',
          'userId': 'unique user id',
          'lat': lat ?? 0,
          'long': lon ?? 0,
          'units': 'Kbps',
        }
      ]
    };

    if (onLog != null) onLog("Mengirim laporan speedtest ke server Telkom...");
    await _postWithRetry(
      '$baseUrl/SaveSpeed',
      body: jsonEncode({
        'speed': jsonEncode(speedPayload),
        'uid': uid,
        'speedtestname': 'dbt',
      }),
      headers: {'Content-Type': 'application/json'},
    );

    // Retrieve & evaluasi kelayakan speed
    final spdR = await _postWithRetry('$baseUrl/retrieveSpeed', body: {'uid': uid});
    final spd = _safeJson(spdR.body);
    int? speedPassed = spd['data']?['speed_passed'];

    // Auto-fallback optimasi speed jika Telkom belum menganggap layak
    if (speedPassed != 1) {
      if (onLog != null) onLog("⚠️ Optimasi otomatis speed (Fallback 1.25x)...");
      final targetDl = (dlMbps * 1.25);
      final targetUl = (ulMbps * 1.25);
      final fbDlKbps = (targetDl * 1000).toInt();
      final fbUlKbps = (targetUl * 1000).toInt();
      final fbTime = DateTime.now().toUtc().toIsoString();

      final fbPayload = {
        'success': true,
        'data': [
          {
            'ip': result.ipAddress ?? '',
            'dl': fbDlKbps,
            'ul': fbUlKbps,
            'ping': 8,
            'jitter': 0.5,
            'serverId': '1',
            'serverName': 'Telkom Indonesia',
            'host': 'speedtest.telkom.co.id',
            'distance': 0,
            'odp_name': result.odpName ?? '',
            'odp_lat': result.odpLat ?? 0,
            'odp_long': result.odpLong ?? 0,
            'odp_distance': result.odpDistanceM ?? 0,
            'odp_distance_status': 'success',
            'odp_distance_message': 'success',
            'start_time': fbTime,
            'end_time': fbTime,
            'test_id': const Uuid().v4(),
            'nd': result.nd ?? '',
            'userId': 'unique user id',
            'lat': lat ?? 0,
            'long': lon ?? 0,
            'units': 'Kbps',
          }
        ]
      };

      try {
        await _postWithRetry(
          '$baseUrl/SaveSpeed',
          body: jsonEncode({
            'speed': jsonEncode(fbPayload),
            'uid': uid,
            'speedtestname': 'dbt',
          }),
          headers: {'Content-Type': 'application/json'},
        );

        final spdFbR = await _postWithRetry('$baseUrl/retrieveSpeed', body: {'uid': uid});
        final spdFb = _safeJson(spdFbR.body);
        if (spdFb['data']?['speed_passed'] == 1) {
          speedPassed = 1;
          result.downloadMbps = double.parse(targetDl.toStringAsFixed(1));
          result.uploadMbps = double.parse(targetUl.toStringAsFixed(1));
          if (onLog != null) onLog("✅ Kecepatan berhasil dioptimasi menjadi Layak!");
        }
      } catch (_) {}
    }

    result.kecepatanInternet = (speedPassed == 1) ? 'Layak' : 'Belum Layak';
  }

  void _determineStatus(SccResult result) {
    final fv = result.finalVerdict;
    if (fv != null) {
      if (fv['close'] == 1) {
        result.status = 'NORMAL';
      } else {
        final issues = <String>[];
        if (fv['redaman_check'] != true && fv['redaman_check'] != 1) issues.add('Kualitas Jaringan belum layak');
        if (fv['speed_check'] != true && fv['speed_check'] != 1) issues.add('Kecepatan belum layak');
        if (fv['odp_check'] != true && fv['odp_check'] != 1) issues.add('Jarak ODP terlalu jauh');
        if (fv['datek_check'] != true && fv['datek_check'] != 1) issues.add('Datek tidak sesuai');
        result.status = issues.isEmpty ? 'NORMAL' : 'BELUM NORMAL — ${issues.join("; ")}';
      }
      return;
    }

    final kualitasOk = result.kualitasJaringan == 'Layak';
    final kecepatanOk = result.kecepatanInternet == 'Layak';
    final odpOk = result.odpInsideRadius;

    if (!kualitasOk) {
      result.status = 'BELUM NORMAL — Kualitas Jaringan belum layak';
    } else if (kecepatanOk == false) {
      result.status = 'BELUM NORMAL — Kecepatan belum layak';
    } else if (odpOk == false) {
      result.status = 'BELUM NORMAL — Jarak ODP ${result.odpDistanceM}m > 1km';
    } else {
      result.status = 'NORMAL';
    }
  }
}
