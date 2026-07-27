import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

abstract interface class HealthStorage {
  String? read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

class EncryptedHealthStorage implements HealthStorage {
  EncryptedHealthStorage._(this._box);

  static const String _boxName = 'vitamind_health_v1';
  static const String _encryptionKeyName = 'vitamind.health_key.v1';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    // The standard macOS Keychain remains OS-encrypted and works for local
    // Debug builds that do not have an Apple provisioning profile.
    mOptions: MacOsOptions(usesDataProtectionKeychain: false),
  );

  final Box<String> _box;

  static Future<EncryptedHealthStorage> create() async {
    await Hive.initFlutter('vitamind');

    var encodedKey = await _secureStorage.read(key: _encryptionKeyName);
    if (encodedKey == null) {
      encodedKey = base64UrlEncode(Hive.generateSecureKey());
      await _secureStorage.write(key: _encryptionKeyName, value: encodedKey);
    }

    final encryptionKey = base64Url.decode(encodedKey);
    if (encryptionKey.length != 32) {
      throw StateError('The VitaMind local encryption key is invalid.');
    }

    final box = await Hive.openBox<String>(
      _boxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    return EncryptedHealthStorage._(box);
  }

  @override
  String? read(String key) => _box.get(key);

  @override
  Future<void> write(String key, String value) async {
    await _box.put(key, value);
  }

  @override
  Future<void> delete(String key) async {
    await _box.delete(key);
  }
}

class MemoryHealthStorage implements HealthStorage {
  final Map<String, String> _values = {};

  @override
  String? read(String key) => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}
