import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'sos_packet.dart';
import 'sos_advertiser.dart';

class DetectedSOS {
  final SosPacket packet;
  final int rssi;

  DetectedSOS(this.packet, this.rssi);
}

class SosScanner {
  final _controller = StreamController<Map<String, DetectedSOS>>.broadcast();

StreamSubscription? _scanSub; // ✅ ADD THIS
  final Map<String, String> _headers = {};
  final Map<String, String> _locations = {};
  final Map<String, DetectedSOS> _active = {}; // ✅ DEDUPED by sosId
  final Set<String> _suppressed = {}; // ✅ ADD
  final Set<String> _relayed = {};

  final SosAdvertiser _advertiser = SosAdvertiser();

  Stream<Map<String, DetectedSOS>> get stream => _controller.stream;

  void start() {
    stop();
    print("🟢 SCANNER STARTED");
    FlutterBluePlus.startScan();

    _scanSub = FlutterBluePlus.scanResults.listen((results) {

      for (final r in results) {
        final manufacturerData = r.advertisementData.manufacturerData;
        if (manufacturerData.isEmpty) continue;

        for (final bytes in manufacturerData.values) {
          try {
            final raw = _bytesToHex(bytes);

            if (!raw.startsWith("4848") && !raw.startsWith("484C")) continue;

            final decoded = SosPacket.fromHex(raw);
            final parts = decoded.split("|");
            if (parts.length < 2) continue;

            final type = parts[0];
            final sosId = parts[1];
            if (_suppressed.contains(sosId)) continue;

            if (type == "HH") _headers[sosId] = decoded;
            if (type == "HL") _locations[sosId] = decoded;

            if (_headers.containsKey(sosId) &&
                _locations.containsKey(sosId)) {
              final h = _headers[sosId]!.split("|");
              final l = _locations[sosId]!.split("|");

              final packet = SosPacket(
                sosId: sosId,
                deviceId: h[2],
                hops: int.parse(h[3]),
                lat: int.parse(l[2]) / 10000,
                lon: int.parse(l[3]) / 10000,
                emergency: h.length > 4 ? h[4] : "Emergency", // ✅ FIX
              );  

              // ✅ UPDATE or INSERT (NO DUPLICATES)
              final previous = _active[sosId];

              // Emit only if new or RSSI changed
              if (previous == null || previous.rssi != r.rssi) {
                  _active[sosId] = DetectedSOS(packet, r.rssi);
                  _controller.add(Map.from(_active));
              }


              // Relay once
              if (!_relayed.contains(sosId) && packet.hops < 5) {
                _relayed.add(sosId);
                _advertiser.start(
                  SosPacket(
                    sosId: packet.sosId,
                    deviceId: packet.deviceId,
                    lat: packet.lat,
                    lon: packet.lon,
                    emergency: packet.emergency,
                    hops: packet.hops + 1,
                  ),
                );
              }
            }
          } catch (_) {}
        }
      }
    });
  }

  void stop() {
  _scanSub?.cancel();      // ✅ cancel listener
  FlutterBluePlus.stopScan();
  _relayed.clear();
}

void suppress(String sosId) {
  _suppressed.add(sosId);
  _active.remove(sosId);
  _controller.add(Map.from(_active));
}

  String _bytesToHex(List<int> bytes) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }
}
