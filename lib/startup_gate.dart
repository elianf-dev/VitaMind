import 'package:flutter/material.dart';

import 'screens/startup_recovery_screen.dart';
import 'services/local_storage_service.dart';

typedef LocalStorageFactory = Future<LocalStorageService> Function();
typedef AppLauncher = Future<Widget> Function(LocalStorageService storage);

/// Opens local storage, then the app. If startup fails (for example the
/// Keystore can't give back the encryption key, or the Hive box won't open),
/// it shows [StartupRecoveryScreen] instead of a white screen (S4, risk R4).
class StartupGate extends StatefulWidget {
  const StartupGate({
    super.key,
    required this.storageFactory,
    required this.resetLocalData,
    required this.launchApp,
    this.onFirstContent,
  });

  /// Opens local storage. Production passes [LocalStorageService.create].
  final LocalStorageFactory storageFactory;

  /// Deletes the local store and its key. Production passes
  /// [LocalStorageService.resetLocalStore].
  final Future<void> Function() resetLocalData;

  /// Runs the rest of startup with opened storage and returns the app.
  final AppLauncher launchApp;

  /// Called once, the first time there is something to show (the app or
  /// the recovery screen). `main()` uses it to release the deferred first
  /// frame, so the native splash stays up while startup runs.
  final VoidCallback? onFirstContent;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  Widget? _app;
  bool _failed = false;
  bool _storageFailed = false;
  bool _busy = true;
  int _failures = 0;
  bool _firstContentShown = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() => _busy = true);
    Widget? app;
    // Only a failure to open local storage (key read or Hive open) offers
    // the reset; a later failure has nothing to do with local data
    // (SEC-S4-1 / QA-S4-1).
    var storageFailed = true;
    try {
      final storage = await widget.storageFactory();
      storageFailed = false;
      app = await widget.launchApp(storage);
    } on Object catch (error, stack) {
      debugPrint(
        'VitaMind: startup failed '
        '(${storageFailed ? 'opening local storage' : 'after storage opened'})'
        ': $error\n$stack',
      );
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      if (app != null) {
        _app = app;
        _failed = false;
      } else {
        _failed = true;
        _storageFailed = storageFailed;
        _failures++;
      }
    });
    _releaseFirstFrame();
  }

  Future<void> _reset() async {
    setState(() => _busy = true);
    try {
      await widget.resetLocalData();
    } on Object catch (error, stack) {
      // Still retry: a partial reset may be enough to open a fresh store.
      debugPrint('VitaMind: local data reset failed: $error\n$stack');
    }
    await _start();
  }

  void _releaseFirstFrame() {
    if (_firstContentShown) {
      return;
    }
    _firstContentShown = true;
    widget.onFirstContent?.call();
  }

  @override
  Widget build(BuildContext context) {
    final app = _app;
    if (app != null) {
      return app;
    }
    if (!_failed) {
      // First attempt still running; the native splash covers this.
      return const SizedBox.shrink();
    }
    return StartupRecoveryApp(
      busy: _busy,
      storageFailed: _storageFailed,
      failedBefore: _failures > 1,
      onTryAgain: _start,
      onReset: _reset,
    );
  }
}
