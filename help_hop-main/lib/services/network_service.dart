import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  NetworkService() {
    _connectivity.onConnectivityChanged.listen((result) {
      if (!_controller.isClosed) {
        _controller.add(_isOnline(result));
      }
    });
  }

  Stream<bool> get onStatusChange => _controller.stream;

  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return _isOnline(result);
  }

  bool _isOnline(ConnectivityResult result) {
    return result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi;
  }

  // ❌ DO NOT CLOSE
  void dispose() {}
}