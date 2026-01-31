import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'sos_packet.g.dart';

@HiveType(typeId: 0)
class SosPacket extends HiveObject {
  @HiveField(0)
  String packetId;

  @HiveField(1)
  String senderId;

  @HiveField(2)
  String encryptedPayload;

  @HiveField(3)
  double lat;

  @HiveField(4)
  double lon;

  @HiveField(5)
  int timestamp;

  @HiveField(6)
  String status; // PENDING | FORWARDED | UPLOADED

  SosPacket({
    String? packetId,
    required this.senderId,
    required this.encryptedPayload,
    required this.lat,
    required this.lon,
    required this.timestamp,
    this.status = 'PENDING',
  }) : packetId = packetId ?? const Uuid().v4();
  /// Serialize to JSON for mesh transmission
  Map<String, dynamic> toJson() => {
        'packetId': packetId,
        'senderId': senderId,
        'encryptedPayload': encryptedPayload,
        'lat': lat,
        'lon': lon,
        'timestamp': timestamp,
        'status': status,
      };

  /// Deserialize from JSON
  factory SosPacket.fromJson(Map<String, dynamic> json) {
    return SosPacket(
      packetId: json['packetId'],
      senderId: json['senderId'],
      encryptedPayload: json['encryptedPayload'],
      lat: json['lat'],
      lon: json['lon'],
      timestamp: json['timestamp'],
      status: json['status'],
    );
  }
}
