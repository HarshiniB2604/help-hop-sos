import 'package:hive/hive.dart';
import '../models/sos_packet.dart';

/// Handles persistent storage of SOS packets using Hive.
/// Acts as the local store for delay-tolerant mesh networking.
class StorageService {
  static const String boxName = 'sos_packets';

  /// Opens (or creates) the Hive box for SOS packets.
  Future<Box<SosPacket>> openBox() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SosPacketAdapter());
    }
    return await Hive.openBox<SosPacket>(boxName);
  }

  /// Adds or updates a packet in local storage.
  /// Used when device is offline or when upload fails.
  Future<void> addPacket(SosPacket packet) async {
    final box = await openBox();
    await box.put(packet.packetId, packet);
  }

  /// Returns all packets that still need to be uploaded.
  /// These are packets stored during offline periods.
  Future<List<SosPacket>> getPendingPackets() async {
    final box = await openBox();
    return box.values
        .where((p) =>
            p.status == 'PENDING' ||
            p.status == 'FORWARDED')
        .toList();
  }

  /// Marks a packet as sent (optional intermediate state).
  /// Useful if you later add peer-to-peer forwarding.
  Future<void> markAsSent(String packetId) async {
    final box = await openBox();
    final packet = box.get(packetId);
    if (packet != null) {
      packet.status = 'FORWARDED';
      await packet.save();
    }
  }

  /// Marks a packet as successfully uploaded to backend.
  /// This prevents duplicate uploads.
  Future<void> markAsUploaded(String packetId) async {
    final box = await openBox();
    final packet = box.get(packetId);
    if (packet != null) {
      packet.status = 'UPLOADED';
      await packet.save();
    }
  }
}