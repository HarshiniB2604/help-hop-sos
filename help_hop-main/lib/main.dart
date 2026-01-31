/*
==============================================
HelpHop - Secure Disaster Response App
==============================================

SETUP INSTRUCTIONS:
1. Create a new Flutter project:
   flutter create helphop

2. Replace lib/main.dart with this entire file

3. Add dependencies to pubspec.yaml:
   dependencies:
     flutter:
       sdk: flutter
     shared_preferences: ^2.2.2
     intl: ^0.18.1

4. Get dependencies:
   flutter pub get

5. Run the app:
   flutter run

Built with ❤️ by Huda Fatimah, Manyashree S, 
Devisri Harshini Baramal, and G. Roweena Siphora
DTL Project: Secure Mesh-based Disaster Response App
==============================================
*/

// ================= BLE (mesh) =================
import 'ble/sos_scanner.dart';
import 'ble/sos_advertiser.dart';
import 'ble/sos_packet.dart' as ble;

// ================= App / Backend =================
import 'models/sos_packet.dart';
import 'services/queue_manager.dart';
import 'services/network_service.dart';

// ================= Flutter / Utils =================
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math';
import 'utils/location_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/api_service.dart';
import 'config/api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const HelpHopApp());
}

// Main App Widget
class HelpHopApp extends StatelessWidget {
  const HelpHopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HelpHop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AppInitializer(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// App Initializer - checks if onboarding is complete

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  bool _isOnboarded = false;
  String? _userRole; // 'victim' or 'rescuer'

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role'); // 'victim' or 'rescuer'
    final onboarded = prefs.getBool('onboarding_complete') ?? false;

    setState(() {
      _userRole = role;
      _isOnboarded = onboarded;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // First time: no role chosen yet
    if (_userRole == null) {
      return const RoleSelectionScreen();
    }

    // Rescuer flow → always ask for PIN
    if (_userRole == 'rescuer') {
      return RescuerHomeScreen();
    }

    // Victim flow
    if (_userRole == 'victim') {
      return _isOnboarded
          ? const MainNavigationScreen()
          : const OnboardingScreen();
    }

    // Fallback
    return const RoleSelectionScreen();
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Future<void> _chooseVictim(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', 'victim');
    await prefs.setBool('onboarding_complete', false);

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  Future<void> _chooseRescuer(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', 'rescuer');

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => RescuerHomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HelpHop'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // 👈 FIXED
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Icon(
                Icons.shield_outlined,
                size: 72,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Choose Your Role',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Are you a person needing help or a rescuer in the field?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 32),

              // Victim Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.person_outline, size: 40),
                      const SizedBox(height: 8),
                      const Text(
                        'I am a Victim / Normal User',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'I want to send SOS, share my location, and message my contacts.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => _chooseVictim(context),
                          child: const Text('Continue as Victim'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Rescuer Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.volunteer_activism_outlined, size: 40),
                      const SizedBox(height: 8),
                      const Text(
                        'I am a Rescuer',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'I want to see SOS requests and respond to them.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _chooseRescuer(context),
                          child: const Text('Continue as Rescuer'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class RescuerHomeScreen extends StatefulWidget {
  const RescuerHomeScreen({super.key});

  @override
  State<RescuerHomeScreen> createState() => _RescuerHomeScreenState();
}

class _RescuerHomeScreenState extends State<RescuerHomeScreen> {
  final SosScanner _scanner = SosScanner();
  StreamSubscription? _bleSub;
  bool _isOnline = false;
  late final StreamSubscription _netSub;
  Timer? _pollingTimer;
  static const Duration _pollInterval = Duration(seconds: 5);

  List<SosRequest> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _netSub = NetworkService().onStatusChange.listen((online) {
      _isOnline = online;

      if (online) {
        // 🌐 ONLINE → backend only
        _scanner.stop();
        _bleSub?.cancel();

        _fetchIncidents();
        _startPolling(); // ✅ START POLLING
      } else {
        // 📴 OFFLINE → BLE only
        _stopPolling(); // ❌ STOP POLLING

        _scanner.start();
        _listenToBle();
      }
    });

    // Initialize once
    NetworkService().isOnline.then((online) {
      _isOnline = online;

      if (online) {
        _fetchIncidents();
        _startPolling(); // ✅ START POLLING
      } else {
        _scanner.start();
        _listenToBle();
      }
    });
  }

  void _startPolling() {
    _pollingTimer?.cancel();

    _pollingTimer = Timer.periodic(_pollInterval, (_) async {
      if (!mounted || !_isOnline) return;
      await _fetchIncidents();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _listenToBle() {
    _bleSub?.cancel();

    _bleSub = _scanner.stream.listen((map) {
      if (!mounted ) return;

      setState(() {
        for (final detected in map.values) {
          final p = detected.packet;
          final baseId = p.sosId;

          // ❌ Already exists (online OR offline) → ignore
          if (_requests.any((r) => r.id.replaceFirst('BLE_', '') == baseId)) {
            return;
          }

          _requests.insert(
            0,
            SosRequest(
              id: 'BLE_$baseId',
              name: p.deviceId,
              emergencyType: p.emergency,
              medicalInfo: 'Received via mesh',
              latitude: p.lat,
              longitude: p.lon,
              approxDistance: 'Nearby',
              messages: const [],
            ),
          );
        }
      });
    });
  }
  
  
  @override
  void dispose() {
    _bleSub?.cancel();
    _netSub.cancel();
    _scanner.stop();
    _pollingTimer?.cancel();
    super.dispose();
  }

  String _extractType(String msg) {
    final match = RegExp(r'TYPE:([^|]+)').firstMatch(msg);
    return match?.group(1)?.trim() ?? 'Emergency';
  }

  Future<void> _fetchIncidents() async {
    final online = await NetworkService().isOnline;
    if (!online) return;

    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/incidents/pending'),
    );

    if (res.statusCode != 200 || !mounted) return;

    final data = jsonDecode(res.body) as List;

    final backend = data.map<SosRequest>((i) {
      return SosRequest(
        id: i['_id'],
        name: i['senderId'],
        emergencyType: _extractType(i['message'] ?? ''),
        medicalInfo: i['message'] ?? '',
        latitude: (i['lat'] as num).toDouble(),
        longitude: (i['lon'] as num).toDouble(),
        approxDistance: 'Nearby',
        messages: const [],
      );
    }).toList();

    setState(() {
      // 1️⃣ Remove old backend entries
      _requests.removeWhere((r) => !r.id.startsWith('BLE_'));

      // 2️⃣ Add backend entries (deduped)
      for (final incident in backend) {
        if (_requests.any(
          (r) => r.id.replaceFirst('BLE_', '') == incident.id,
        )) {
          continue;
        }

        _requests.add(incident);

        // 3️⃣ Suppress BLE only AFTER backend confirms
        _scanner.suppress(incident.id);
      }

      _loading = false;
    });
  }

  void removeRequest(String id) async {
    setState(() {
      _requests.removeWhere((r) => r.id == id);
    });

    // 🔕 Stop BLE rebroadcast permanently
    if (id.startsWith('BLE_')) {
      _scanner.suppress(id.replaceFirst('BLE_', ''));
      return;
    }

    // 🔁 Backend refresh
    await _fetchIncidents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rescuer Dashboard')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('No SOS received yet'))
              : ListView.builder(
                  itemCount: _requests.length,
                  itemBuilder: (_, i) {
                    final sos = _requests[i];
                    return Card(
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text('${sos.emergencyType} – ${sos.name}'),
                            ),

                            if (sos.id.startsWith('BLE_'))
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Offline SOS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text('Distance: ${sos.approxDistance}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RescuerSosDetailScreen(
                                sosRequest: sos,
                                scanner: _scanner, // ✅ REQUIRED
                                onRescued: () {
                                  _scanner.suppress(sos.id.replaceFirst('BLE_', ''));
                                  removeRequest(sos.id);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

class RescuerSosDetailScreen extends StatefulWidget {
  final SosRequest sosRequest;
  final VoidCallback onRescued;
  final SosScanner scanner;

  const RescuerSosDetailScreen({
    super.key,
    required this.sosRequest,
    required this.onRescued,
    required this.scanner,
  });

  @override
  State<RescuerSosDetailScreen> createState() =>
      _RescuerSosDetailScreenState();
}

class _RescuerSosDetailScreenState extends State<RescuerSosDetailScreen> {
  final ApiService _api = ApiService();

  bool _accepted = false;
  bool _rescued = false;
  

  final TextEditingController _chatController = TextEditingController();
  List<IncidentMessage> _messages = [];

  Timer? _pollingTimer;

  // Demo rescuer location
  final double _rescuerLat = 12.9700;
  final double _rescuerLon = 77.5900;

  @override
  void initState() {
    super.initState();
    _messages = List.from(widget.sosRequest.messages);
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _chatController.dispose();
    super.dispose();
  }

  // ============================
  // POLLING
  // ============================
  void _startPolling() {
    _pollingTimer?.cancel();

    if (_isBleOnly()) return;

    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) async {
        final online = await NetworkService().isOnline;
        if (online) {
          _fetchIncidents();
        }
      },
    );
  }

  bool _isBleOnly() {
    
    // MongoDB ObjectId is 24 chars
    return widget.sosRequest.id.startsWith('BLE_');
  }

  // ============================
  // FETCH INCIDENT
  // ============================
  Future<void> _fetchIncidents() async {
    if (_isBleOnly()) return;

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/incidents/${widget.sosRequest.id}'),
      );

      if (res.statusCode != 200) return;

      final decoded = jsonDecode(res.body);
      final incident =
        decoded is Map && decoded['incident'] != null
            ? decoded['incident']
            : decoded;

      final List<dynamic> msgs =
        (incident['messages'] as List?) ?? [];

      if (!mounted) return;

      setState(() {
        _messages = msgs
          .map((m) => IncidentMessage.fromJson(
              Map<String, dynamic>.from(m)))
          .toList();
      });
    } catch (_) {}
  }

  // ============================
  // SEND CHAT MESSAGE
  // ============================
  Future<void> _sendMessage() async {
    if (_isBleOnly()) return;
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final incidentId = widget.sosRequest.id;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/incidents/$incidentId/message'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'from': 'rescuer',
          'text': text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _chatController.clear();
        await _fetchIncidents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send message (code ${response.statusCode})',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error while sending message')),
      );
    }
  }

  // ============================
  // MARK AS RESCUED
  // ============================
  Future<void> _markRescued() async {
    if (_isBleOnly()) {
      widget.onRescued();
      Navigator.pop(context);
      return;
    }

    final success =
      await _api.resolveIncident(widget.sosRequest.id);

    if (!mounted) return;

    if (success) {
      widget.onRescued();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to mark as rescued')),
      );
    }
  }
  // ============================
  // DIRECTION (DEMO)
  // ============================
  String _direction() {
    final dLat = widget.sosRequest.latitude - _rescuerLat;
    final dLon = widget.sosRequest.longitude - _rescuerLon;

    if (dLat.abs() < 0.0005 && dLon.abs() < 0.0005) {
      return 'You are at victim location';
    }

    return 'Move '
        '${dLat > 0 ? 'North' : 'South'}-'
        '${dLon > 0 ? 'East' : 'West'}';
  }

  // ============================
  // UI
  // ============================
  @override
  Widget build(BuildContext context) {
    final sos = widget.sosRequest;

    return Scaffold(
      appBar: AppBar(title: const Text('SOS Details')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sos.emergencyType,
                style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),

              Text(
                'Victim: ${sos.name}',
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: 8),

              Text(
                'Location: ${sos.latitude.toStringAsFixed(5)}, '
                '${sos.longitude.toStringAsFixed(5)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const Divider(height: 24),

              // 💬 CHAT AREA
              Expanded(
                child: ListView(
                  children: _messages
                  .map(
                    (m) => ListTile(
                      title: Text(m.text),
                      subtitle: Text(
                        DateFormat('hh:mm a').format(m.timestamp),
                      ),
                      trailing: m.from == 'rescuer'
                        ? const Icon(Icons.person)
                        : const Icon(Icons.person_outline),
                    ),
                  )
                  .toList(),
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      decoration:
                      const InputDecoration(hintText: 'Message'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  )
                ],
              ),

              const SizedBox(height: 8),

              if (!_accepted)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                        setState(() => _accepted = true),
                      child: const Text('ACCEPT'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('REJECT'),
                    ),
                  ),
                ],
              )
              else ...[
                Text(_direction()),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _rescued ? null : _markRescued,
                  child: const Text('MARK AS RESCUED'),
                )
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ==============================================
// ONBOARDING SCREENS
// ==============================================

// Main Onboarding Screen with PageView
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form data
  final Map<String, dynamic> _formData = {
    'name': '',
    'phone': '',
    'location': '',
    'bloodGroup': 'O+',
    'allergies': <String>[],
    'emergencyName': '',
    'emergencyPhone': '',
    'allowGPS': true,
  };

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    // Generate unique device ID
    final deviceId = _generateDeviceId();

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _formData['name']);
    await prefs.setString('user_phone', _formData['phone']);
    await prefs.setString('user_location', _formData['location']);
    await prefs.setString('user_blood_group', _formData['bloodGroup']);
    await prefs.setStringList('user_allergies', _formData['allergies']);
    await prefs.setString('emergency_name', _formData['emergencyName']);
    await prefs.setString('emergency_phone', _formData['emergencyPhone']);
    await prefs.setBool('allow_gps', _formData['allowGPS']);
    await prefs.setString('device_id', deviceId);
    await prefs.setBool('onboarding_complete', true);

    if (mounted) {
      // Show welcome message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Welcome, ${_formData['name']}! Your Device ID: $deviceId'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to main screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  String _generateDeviceId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final part1 =
        List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    final part2 =
        List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    return '$part1-$part2';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup HelpHop'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress Indicator
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: List.generate(3, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index <= _currentPage
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          // PageView
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              physics: const NeverScrollableScrollPhysics(),
              children: [
                OnboardingStep1(
                  formData: _formData,
                  onNext: _nextPage,
                ),
                OnboardingStep2(
                  formData: _formData,
                  onNext: _nextPage,
                  onBack: _previousPage,
                ),
                OnboardingStep3(
                  formData: _formData,
                  onComplete: _completeOnboarding,
                  onBack: _previousPage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Step 1: Basic Details
class OnboardingStep1 extends StatefulWidget {
  final Map<String, dynamic> formData;
  final VoidCallback onNext;

  const OnboardingStep1({
    super.key,
    required this.formData,
    required this.onNext,
  });

  @override
  State<OnboardingStep1> createState() => _OnboardingStep1State();
}

class _OnboardingStep1State extends State<OnboardingStep1> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step 1: Basic Details',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Help us personalize your experience',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),

            // Name Field
            TextFormField(
              initialValue: widget.formData['name'],
              decoration: const InputDecoration(
                labelText: 'Name / Nickname',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
              onChanged: (value) => widget.formData['name'] = value,
            ),
            const SizedBox(height: 16),

            // Phone Field
            TextFormField(
              initialValue: widget.formData['phone'],
              decoration: const InputDecoration(
                labelText: 'Phone Number (Optional)',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) => widget.formData['phone'] = value,
            ),
            const SizedBox(height: 16),

            // Next Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onNext();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Step 2: Location & Health Info
class OnboardingStep2 extends StatefulWidget {
  final Map<String, dynamic> formData;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const OnboardingStep2({
    super.key,
    required this.formData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<OnboardingStep2> createState() => _OnboardingStep2State();
}

class _OnboardingStep2State extends State<OnboardingStep2> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _availableAllergies = [
    'None',
    'Peanuts',
    'Shellfish',
    'Penicillin',
    'Insulin',
    'Aspirin',
    'Latex',
    'Dust',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step 2: Location & Health',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'This info helps rescuers assist you better',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),

            // Location Field
            TextFormField(
              initialValue: widget.formData['location'],
              decoration: const InputDecoration(
                labelText: 'Home Location / Pin Code',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your location';
                }
                return null;
              },
              onChanged: (value) => widget.formData['location'] = value,
            ),
            const SizedBox(height: 16),

            // Blood Group Dropdown
            DropdownButtonFormField<String>(
              value: widget.formData['bloodGroup'],
              decoration: const InputDecoration(
                labelText: 'Blood Group',
                prefixIcon: Icon(Icons.bloodtype),
                border: OutlineInputBorder(),
              ),
              items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                  .map((bg) => DropdownMenuItem(
                        value: bg,
                        child: Text(bg),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  widget.formData['bloodGroup'] = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Allergies Section
            Text(
              'Allergies / Medical Conditions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _availableAllergies.map((allergy) {
                final List<String> selectedAllergies =
                    (widget.formData['allergies'] as List<String>);
                final bool isSelected = selectedAllergies.contains(allergy);

                return FilterChip(
                  label: Text(allergy),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (allergy == 'None') {
                        if (selected) {
                          // If "None" is selected → clear all others and keep only "None"
                          selectedAllergies
                            ..clear()
                            ..add('None');
                        } else {
                          // Unselect "None"
                          selectedAllergies.remove('None');
                        }
                      } else {
                        // If selecting any other allergy
                        if (selected) {
                          // Remove "None" if it was selected
                          selectedAllergies.remove('None');
                          selectedAllergies.add(allergy);
                        } else {
                          selectedAllergies.remove(allergy);
                        }
                      }
                      widget.formData['allergies'] = selectedAllergies;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Navigation Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onBack,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        widget.onNext();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text('Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Step 3: Emergency Contact & Permissions
class OnboardingStep3 extends StatefulWidget {
  final Map<String, dynamic> formData;
  final VoidCallback onComplete;
  final VoidCallback onBack;

  const OnboardingStep3({
    super.key,
    required this.formData,
    required this.onComplete,
    required this.onBack,
  });

  @override
  State<OnboardingStep3> createState() => _OnboardingStep3State();
}

class _OnboardingStep3State extends State<OnboardingStep3> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step 3: Emergency Contact',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Who should we contact in an emergency?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),

            // Emergency Contact Name
            TextFormField(
              initialValue: widget.formData['emergencyName'],
              decoration: const InputDecoration(
                labelText: 'Emergency Contact Name',
                prefixIcon: Icon(Icons.contacts),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter emergency contact name';
                }
                return null;
              },
              onChanged: (value) => widget.formData['emergencyName'] = value,
            ),
            const SizedBox(height: 16),

            // Emergency Contact Phone
            TextFormField(
              initialValue: widget.formData['emergencyPhone'],
              decoration: const InputDecoration(
                labelText: 'Emergency Contact Number',
                prefixIcon: Icon(Icons.phone_in_talk),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter emergency contact number';
                }
                return null;
              },
              onChanged: (value) => widget.formData['emergencyPhone'] = value,
            ),
            const SizedBox(height: 24),

            // GPS Permission Checkbox
            Card(
              child: CheckboxListTile(
                title: const Text('Allow sharing my GPS location during SOS'),
                subtitle: const Text('Helps rescuers locate you quickly'),
                value: widget.formData['allowGPS'],
                onChanged: (value) {
                  setState(() {
                    widget.formData['allowGPS'] = value ?? true;
                  });
                },
              ),
            ),
            const SizedBox(height: 32),

            // Navigation Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onBack,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        widget.onComplete();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Complete Setup'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class IncidentMessage {
  final String from;
  final String text;
  final DateTime timestamp;

  IncidentMessage({
    required this.from,
    required this.text,
    required this.timestamp,
  });

  factory IncidentMessage.fromJson(Map<String, dynamic> json) {
    return IncidentMessage(
      from: json['from'] ?? '',
      text: json['text'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'].toString())
          : DateTime.now(),
    );
  }
}

typedef Message = IncidentMessage;

class SosRequest {
  final String id;
  final String name;
  final String emergencyType;
  final String medicalInfo;
  final double latitude;
  final double longitude;
  final String approxDistance;
  final List<IncidentMessage> messages;

  const SosRequest({
    required this.id,
    required this.name,
    required this.emergencyType,
    required this.medicalInfo,
    required this.latitude,
    required this.longitude,
    required this.approxDistance,
    required this.messages,
  });
}

// ==============================================
// MAIN NAVIGATION SCREEN
// ==============================================

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const SOSScreen(),
    const ChatScreen(),
    const ProfileScreen(),
    const SettingsScreen(),
    const HelpScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
          NavigationDestination(
            icon: Icon(Icons.help_outline),
            selectedIcon: Icon(Icons.help),
            label: 'Help',
          ),
        ],
      ),
    );
  }
}

// ==============================================
// SOS SCREEN
// ==============================================

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  String _userName = '';
  String _lastSosTime = 'Never';
  final TextEditingController _noteController = TextEditingController();

  final QueueManager _queueManager = QueueManager();

  @override
  void initState() {
    super.initState();
    _queueManager.flushPendingToBackend();
    _loadUserData();

    
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'User';
      _lastSosTime = prefs.getString('last_sos_time') ?? 'Never';
    });
  }

  void _showEmergencyTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('What type of emergency?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEmergencyOption('Flood', Icons.water),
            _buildEmergencyOption('Earthquake', Icons.vibration),
            _buildEmergencyOption('Fire', Icons.local_fire_department),
            _buildEmergencyOption('Landslide', Icons.landscape),
            _buildEmergencyOption('Other', Icons.warning),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyOption(String type, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.red),
      title: Text(type),
      onTap: () {
        Navigator.pop(context);
        _startCountdown(type);
      },
    );
  }

  void _startCountdown(String emergencyType) {
    int countdown = 5;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (countdown > 0) {
            Future.delayed(const Duration(seconds: 1), () {
              if (context.mounted) {
                setDialogState(() {
                  countdown--;
                });
              }
            });
          } else {
            Future.delayed(Duration.zero, () {
              if (context.mounted) {
                Navigator.pop(context);
                _sendSOS(emergencyType);
              }
            });
          }

          return AlertDialog(
            title: Text('Sending SOS: $emergencyType'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$countdown',
                  style: const TextStyle(
                      fontSize: 64, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _sendSOS(String emergencyType) async {
    final prefs = await SharedPreferences.getInstance();

    // 1️⃣ Save last SOS time
    final now = DateFormat('MMM dd, hh:mm a').format(DateTime.now());
    await prefs.setString('last_sos_time', now);

    setState(() {
      _lastSosTime = now;
    });

    // 2️⃣ Get user + note
    final userId = prefs.getString('device_id') ?? 'unknown-device';
    final note = _noteController.text.trim();

    // 3️⃣ Build plaintext message
    final plaintext = 'TYPE:$emergencyType | NOTE:$note | USER:$_userName';

    // 4️⃣ Encrypt (placeholder)
    final encryptedPayload = plaintext;

    // =========================
    // 🔵 BLE MESH ADVERTISING
    // =========================
    final position = await LocationHelper.getLocation();
    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location unavailable. Enable GPS.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final sosId = ble.SosPacket.generateSosId();

    final blePacket = ble.SosPacket(
      sosId: sosId,
      deviceId: userId,
      lat: position.latitude, // replace with GPS later
      lon: position.longitude,
      emergency: emergencyType,
      hops: 0,
    );

    final advertiser = SosAdvertiser();
    await advertiser.start(blePacket);

    // =========================
    // 🧠 BACKEND / DTN QUEUE
    // =========================
    final packet = SosPacket(
      senderId: userId,
      encryptedPayload: encryptedPayload,
      lat: position.latitude,
      lon: position.longitude,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await _queueManager.handlePacket(packet);

    // =========================
    // UI FEEDBACK
    // =========================
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'SOS sent or queued safely\nType: $emergencyType',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HelpHop'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AlertScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Welcome Message
            Text(
              'Welcome, $_userName',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),

            // Status Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    'GPS',
                    '12.9716° N, 77.5946° E',
                    Icons.location_on,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatusCard(
                    'Battery',
                    '85%',
                    Icons.battery_full,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    'Wi-Fi',
                    'Offline',
                    Icons.wifi_off,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatusCard(
                    'Bluetooth',
                    'Active',
                    Icons.bluetooth,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // SOS Button
            GestureDetector(
              onTap: _showEmergencyTypeDialog,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning,
                        size: 64,
                        color: Colors.white,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'SEND SOS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Last SOS Time
            Text(
              'Last SOS: $_lastSosTime',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),

            // Note Field
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Add note (e.g., trapped under stairs)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              value,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================
// CHAT SCREEN
// ==============================================

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final NetworkService _networkService = NetworkService();

  String _userName = 'Me';
  String? _deviceId;
  String? _activeIncidentId;

  Timer? _pollingTimer;
  List<Message> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _userName = prefs.getString('user_name') ?? 'Me';
      _deviceId = prefs.getString('device_id');
      _activeIncidentId = prefs.getString('active_incident_id');
    });

    if (_activeIncidentId == null) {
      await _bindIncidentFromBackend();
    }

    if (_activeIncidentId != null) {
      await _fetchIncident();
      _startPolling();
    }
  }

  Future<void> _bindIncidentFromBackend() async {
    if (_deviceId == null) return;

    final online = await _networkService.isOnline;
    if (!online) return;

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/incidents/user/$_deviceId'),
      );

      if (res.statusCode != 200) return;

      final decoded = jsonDecode(res.body);
      final incidents = decoded['incidents'] as List<dynamic>? ?? [];

      for (final raw in incidents) {
        if (raw is! Map) continue;
        final status = raw['status']?.toString().toLowerCase();
        if (status != 'resolved') {
          _activeIncidentId = raw['_id'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('active_incident_id', _activeIncidentId!);
          break;
        }
      }
    } catch (_) {}
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _fetchIncident(),
    );
  }

  Future<void> _fetchIncident() async {
    if (_activeIncidentId == null) return;

    final online = await _networkService.isOnline;
    if (!online) return;

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/incidents/$_activeIncidentId'),
      );

      if (res.statusCode != 200) return;

      final decoded = jsonDecode(res.body);
      final incident =
          decoded['incident'] is Map ? decoded['incident'] : decoded;

      // ✅ 🔥 ADD THIS BLOCK EXACTLY HERE
      if (incident['status'] == 'resolved') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('active_incident_id');

        if (mounted) {
          setState(() {
            _messages.clear();
            _activeIncidentId = null;
          });
        }

        _pollingTimer?.cancel(); // 🛑 stop polling
        return;
      }
      // ✅ 🔥 END BLOCK

      final List messagesJson =
        (incident['messages'] as List?) ?? [];

      final parsed = messagesJson
        .whereType<Map>()
        .map((m) => Message.fromJson(Map<String, dynamic>.from(m)))
        .toList();

      if (!mounted) return;

      setState(() {
        _messages = parsed;
      });
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    if (_activeIncidentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat available only when online')),
      );
      return;
    }

    final online = await _networkService.isOnline;
    if (!online) return;

    try {
      await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/incidents/$_activeIncidentId/message',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'from': 'victim',
          'text': text,
        }),
      );

      await _fetchIncident();
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Rescuer'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                final isMe = m.from == 'victim';
                final time =
                    DateFormat('hh:mm a').format(m.timestamp);

                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Theme.of(context)
                              .colorScheme
                              .primaryContainer
                          : Theme.of(context)
                              .colorScheme
                              .surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.text),
                        const SizedBox(height: 4),
                        Text(
                          time,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==============================================
// PROFILE SCREEN
// ==============================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userData = {
        'name': prefs.getString('user_name') ?? '',
        'phone': prefs.getString('user_phone') ?? '',
        'location': prefs.getString('user_location') ?? '',
        'bloodGroup': prefs.getString('user_blood_group') ?? '',
        'allergies': prefs.getStringList('user_allergies') ?? [],
        'emergencyName': prefs.getString('emergency_name') ?? '',
        'emergencyPhone': prefs.getString('emergency_phone') ?? '',
        'deviceId': prefs.getString('device_id') ?? '',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Edit functionality can be added here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit profile in Settings')),
              );
            },
          ),
        ],
      ),
      body: _userData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Profile Avatar
                  CircleAvatar(
                    radius: 60,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      _userData['name']?.isNotEmpty == true
                          ? _userData['name'][0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userData['name'] ?? 'Unknown',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Device ID: ${_userData['deviceId']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Personal Information
                  _buildSectionCard(
                    'Personal Information',
                    [
                      _buildInfoRow(Icons.phone, 'Phone',
                          _userData['phone'] ?? 'Not provided'),
                      _buildInfoRow(Icons.location_on, 'Location',
                          _userData['location'] ?? ''),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Medical Information
                  _buildSectionCard(
                    'Medical Information',
                    [
                      _buildInfoRow(Icons.bloodtype, 'Blood Group',
                          _userData['bloodGroup'] ?? ''),
                      _buildInfoRow(
                        Icons.medical_information,
                        'Allergies',
                        (_userData['allergies'] as List).isEmpty
                            ? 'None'
                            : (_userData['allergies'] as List).join(', '),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Emergency Contact
                  _buildSectionCard(
                    'Emergency Contact',
                    [
                      _buildInfoRow(Icons.contacts, 'Name',
                          _userData['emergencyName'] ?? ''),
                      _buildInfoRow(Icons.phone_in_talk, 'Phone',
                          _userData['emergencyPhone'] ?? ''),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================
// SETTINGS SCREEN
// ==============================================

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _anonymousMode = false;
  bool _lowPowerMode = false;
  bool _allowGPS = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _anonymousMode = prefs.getBool('anonymous_mode') ?? false;
      _lowPowerMode = prefs.getBool('low_power_mode') ?? false;
      _allowGPS = prefs.getBool('allow_gps') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _resetData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will clear all your information and restart the onboarding process. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),

          // Privacy Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Privacy',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          SwitchListTile(
            title: const Text('Anonymous Mode'),
            subtitle: const Text('Hide your name in local chat'),
            value: _anonymousMode,
            onChanged: (value) {
              setState(() {
                _anonymousMode = value;
              });
              _saveSetting('anonymous_mode', value);
            },
          ),
          SwitchListTile(
            title: const Text('Share GPS Location'),
            subtitle: const Text('Allow location sharing during SOS'),
            value: _allowGPS,
            onChanged: (value) {
              setState(() {
                _allowGPS = value;
              });
              _saveSetting('allow_gps', value);
            },
          ),
          const Divider(),

          // Connectivity Section
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Connectivity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          SwitchListTile(
            title: const Text('Low-Power Scan Mode'),
            subtitle: const Text('Conserve battery for Bluetooth scanning'),
            value: _lowPowerMode,
            onChanged: (value) {
              setState(() {
                _lowPowerMode = value;
              });
              _saveSetting('low_power_mode', value);
            },
          ),
          const Divider(),

          // Data Management
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Data Management',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export Profile Data'),
            subtitle: const Text('Save your profile as a file'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export feature coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Reset All Data'),
            subtitle: const Text('Clear profile and restart setup'),
            onTap: _resetData,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class AlertScreen extends StatelessWidget {
  const AlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Official Disaster Alert'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 80,
              color: Colors.orange[800],
            ),
            const SizedBox(height: 16),
            const Text(
              'Official Disaster Alert',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Severe weather conditions predicted in your area.\n\n'
              'Please take the following precautions immediately:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildInstruction('Move to higher ground or a safe shelter.'),
            _buildInstruction('Charge your phone and power banks.'),
            _buildInstruction('Keep Wi-Fi and Bluetooth turned ON.'),
            _buildInstruction('Keep essential medicines and documents ready.'),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('ACKNOWLEDGE'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right, size: 24),
          const SizedBox(width: 4),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

// ==============================================
// HELP SCREEN
// ==============================================

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Info'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Info Card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.shield,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'HelpHop',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Secure, Offline-First Disaster Response',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // How to Use SOS
            Text(
              'How to Use SOS Feature',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              '1',
              'Press the red SOS button on the home screen',
            ),
            _buildHelpItem(
              '2',
              'Select your emergency type (Flood, Fire, etc.)',
            ),
            _buildHelpItem(
              '3',
              'Wait for 5-second countdown or cancel if needed',
            ),
            _buildHelpItem(
              '4',
              'Your SOS will be broadcast to nearby devices via mesh network',
            ),
            const SizedBox(height: 24),

            // How Local Chat Works
            Text(
              'How Local Chat Works Offline',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              '📱',
              'Uses Bluetooth and Wi-Fi Direct for device-to-device messaging',
            ),
            _buildHelpItem(
              '🌐',
              'Forms a mesh network with nearby phones (no internet needed)',
            ),
            _buildHelpItem(
              '💬',
              'Messages relay through multiple devices to reach farther',
            ),
            _buildHelpItem(
              '🔒',
              'All communications are encrypted end-to-end',
            ),
            const SizedBox(height: 24),

            // Safety Tips
            Text(
              'Safety Tips for Disasters',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildSafetyTip('Stay calm and assess your situation'),
            _buildSafetyTip('Send SOS immediately if trapped or injured'),
            _buildSafetyTip('Conserve phone battery - enable low-power mode'),
            _buildSafetyTip('Share your location with local chat'),
            _buildSafetyTip('Follow instructions from rescue teams'),
            _buildSafetyTip('Keep your emergency contact informed'),
            const SizedBox(height: 32),

            // Team Info
            const Divider(),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    'Our Team',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Built with ❤️ by',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Huda Fatimah\nManyashree S\nDevisri Harshini Baramal\nG. Roweena Siphora',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'DTL Project:\nSecure Mesh-based Disaster Response App',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 20, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(child: Text(tip)),
        ],
      ),
    );
  }
}
