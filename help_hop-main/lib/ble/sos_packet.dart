import 'dart:convert';
import 'dart:math';

class SosPacket {
  final String sosId;
  final String deviceId;
  final double lat;
  final double lon;
  final String emergency;
  final int hops;

  SosPacket({
    required this.sosId,
    required this.deviceId,
    required this.lat,
    required this.lon,
    required this.emergency,
    required this.hops,
  });

  /// UUID 1 — HEADER
  String encodeHeader() {
    return "HH|$sosId|$deviceId|$hops|$emergency";
  }

  /// UUID 2 — LOCATION (compressed)
  String encodeLocation() {
    final latInt = (lat * 10000).round();
    final lonInt = (lon * 10000).round();
    return "HL|$sosId|$latInt|$lonInt";
  }

  /// Generate short SOS ID
  static String generateSosId() {
    const chars = "ABCDEF0123456789";
    final rand = Random();
    return List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  static String toHex(String s) {
  return utf8
      .encode(s)
      .map((e) => e.toRadixString(16).padLeft(2, '0'))
      .join()
      .toUpperCase();
}


  static String fromHex(String hex) {
    final bytes = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return utf8.decode(bytes);
  }
}
