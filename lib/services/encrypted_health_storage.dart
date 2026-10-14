import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

abstract interface class HealthStorage {
  String? read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);

  /// Removes every stored value, for every profile.
  Future<void> clear();

  /// Rewrites the store so deleted values no longer sit in the file
  /// (SEC-L2-2).
  Future<void> compact();
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

  /// Startup recovery (S4): deletes the encrypted box file and its stored
  /// key, so the next [create] starts with an empty store and a new key.
  /// Each step is tried even if the other fails; the first error is
  /// rethrown afterwards so the caller can log it.
  static Future<void> deleteLocalStore() async {
    Object? firstError;
    StackTrace? firstStack;

    try {
      await Hive.initFlutter('vitamind');
      await Hive.deleteBoxFromDisk(_boxName);
    } on Object catch (error, stack) {
      firstError ??= error;
      firstStack ??= stack;
    }

    try {
      await _secureStorage.delete(key: _encryptionKeyName);
    } on Object catch (error, stack) {
      firstError ??= error;
      firstStack ??= stack;
    }

    if (firstError != null) {
      Error.throwWithStackTrace(firstError, firstStack!);
    }
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

  @override
  Future<void> clear() async {
    await _box.clear();
  }

  /// Hive deletes by appending a tombstone, so old ciphertext stays in the
  /// file until it is compacted.
  @override
  Future<void> compact() async {
    await _box.compact();
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

  @override
  Future<void> clear() async {
    _values.clear();
  }

  /// Nothing is kept after a delete in memory.
  @override
  Future<void> compact() async {}
}
