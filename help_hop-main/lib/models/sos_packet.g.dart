// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sos_packet.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SosPacketAdapter extends TypeAdapter<SosPacket> {
  @override
  final int typeId = 0;

  @override
  SosPacket read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SosPacket(
      packetId: fields[0] as String?,
      senderId: fields[1] as String,
      encryptedPayload: fields[2] as String,
      lat: fields[3] as double,
      lon: fields[4] as double,
      timestamp: fields[5] as int,
      status: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SosPacket obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.packetId)
      ..writeByte(1)
      ..write(obj.senderId)
      ..writeByte(2)
      ..write(obj.encryptedPayload)
      ..writeByte(3)
      ..write(obj.lat)
      ..writeByte(4)
      ..write(obj.lon)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SosPacketAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
