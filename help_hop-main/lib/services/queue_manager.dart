import '../models/sos_packet.dart';
import 'storage_service.dart';
import 'api_service.dart';
import 'network_service.dart';

class QueueManager {
  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();
  final NetworkService _networkService = NetworkService();

  QueueManager() {
    _networkService.onStatusChange.listen((isOnline) {
      if (isOnline) {
        flushPendingToBackend();
      }
    });
  }

  /// ENTRY POINT for SOS
  Future<void> handlePacket(SosPacket packet) async {
    print('📦 SOS received: ${packet.senderId}');
    await _storageService.addPacket(packet);

    if (await _networkService.isOnline) {
      await flushPendingToBackend();
    } else {
      print('📴 Offline — stored locally');
    }
  }

  /// Upload all pending packets
  Future<void> flushPendingToBackend() async {
    final packets = await _storageService.getPendingPackets();

    for (final packet in packets) {
      final success = await _apiService.sendPacket(packet);

      if (success) {
        await _storageService.markAsUploaded(packet.packetId);
        print('✅ Uploaded ${packet.packetId}');
      } else {
        print('❌ Upload failed, will retry');
      }
    }
  }
}