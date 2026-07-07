import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityHelper {
  static final _conn = Connectivity();

  static Future<bool> isConnected() async {
    final result = await _conn.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  static Stream<bool> get onConnectivityChanged =>
      _conn.onConnectivityChanged.map((r) => !r.contains(ConnectivityResult.none));
}
