import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdService {
  DeviceIdService._privateConstructor();
  static final DeviceIdService instance = DeviceIdService._privateConstructor();

  static const _prefKey = 'device_uuid';

  Future<String> _getRawDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_prefKey);
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(_prefKey, id);
    }
    return id;
  }

  Future<String> getHashedDeviceId() async {
    final raw = await _getRawDeviceId();
    final bytes = utf8.encode(raw);
    return sha256.convert(bytes).toString();
  }
}
