import 'dart:typed_data';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'sos_packet.dart';

class SosAdvertiser {
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();

  static const String SOS_SERVICE_UUID =
      "0000FEAA-0000-1000-8000-00805F9B34FB";

  static const int MANUFACTURER_ID = 0xFFFF; // ✅ REQUIRED

  Future<void> start(SosPacket packet) async {
    final headerHex = SosPacket.toHex(packet.encodeHeader());
    final locHex = SosPacket.toHex(packet.encodeLocation());

    // 🔹 Advertise HEADER
    await _peripheral.start(
      advertiseData: AdvertiseData(
        serviceUuid: SOS_SERVICE_UUID,
        manufacturerId: MANUFACTURER_ID,
        manufacturerData: _hexToBytes(headerHex),
        includeDeviceName: false,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 300));

    // 🔹 Advertise LOCATION
    await _peripheral.start(
      advertiseData: AdvertiseData(
        serviceUuid: SOS_SERVICE_UUID,
        manufacturerId: MANUFACTURER_ID,
        manufacturerData: _hexToBytes(locHex),
        includeDeviceName: false,
      ),
    );

    print("🚨 ADVERTISING SOS ${packet.sosId}");
  }

  Future<void> stop() async {
    await _peripheral.stop();
  }

  Uint8List _hexToBytes(String hex) {
    final bytes = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < hex.length; i += 2) {
      bytes[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return bytes;
  }
}
