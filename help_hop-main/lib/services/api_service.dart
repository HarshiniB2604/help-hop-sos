import '../config/api.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sos_packet.dart';

class ApiService {
  /// Send SOS (victim side)
  final String sendSosEndpoint =
      '${ApiConfig.baseUrl}/incidents';

  /// Resolve SOS (rescuer side)
  final String resolveEndpoint =
      '${ApiConfig.baseUrl}/incidents/resolve';

  /// ===============================
  /// SEND SOS
  /// ===============================
  Future<bool> sendPacket(SosPacket packet) async {
    print('🌐 Sending SOS to ${ApiConfig.baseUrl}');
    print('📦 Payload: ${packet.senderId}, ${packet.lat}, ${packet.lon}');

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/incidents'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderId': packet.senderId,
          'message': packet.encryptedPayload,
          'lat': packet.lat,
          'lon': packet.lon,
        }),
      );

      print('📡 Response code: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ API ERROR: $e');
      return false;
    }
  }

  /// ===============================
  /// MARK AS RESCUED
  /// ===============================
  Future<bool> resolveIncident(String incidentId) async {
  try {
    print('🛠 Resolving incident $incidentId');

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/incidents/resolve'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'incidentId': incidentId,
      }),
    );

    print('🛠 Resolve response: ${response.statusCode}');

    return response.statusCode == 200;
  } catch (e) {
    print('❌ API error (resolveIncident): $e');
    return false;
  }
  }
}