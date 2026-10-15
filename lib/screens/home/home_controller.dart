import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/computer_event.dart';
import '../../models/device.dart';
import '../../services/device_repository.dart';

class HomeController extends ChangeNotifier {
  HomeController(this.repository, {Stream<ComputerEvent>? updates})
    : hasLiveUpdates = updates != null {
    _subscription = updates?.listen(
      _event,
      onError: (Object _) {
        if (!_disposed) {
          liveConnected = false;
          notifyListeners();
        }
      },
    );
  }

  final DeviceRepository repository;
  final bool hasLiveUpdates;
  StreamSubscription<ComputerEvent>? _subscription;
  List<Device> _devices = [];
  final Map<String, ComputerStatusChanged> _statuses = {};
  final Set<String> _removed = {};
  final Set<String> _deletedLocally = {};
  bool loading = true,
      formOpen = false,
      loadFailed = false,
      liveConnected = false;
  String? deletingId, poweringId, checkingId;
  int _loadVersion = 0, _snapshotVersion = 0;
  bool _disposed = false;

  List<Device> get devices => List.unmodifiable(_devices);
  bool get busy =>
      loading ||
      formOpen ||
      deletingId != null ||
      poweringId != null ||
      checkingId != null;

  Future<void> load() async {
    final version = ++_loadVersion, snapshotVersion = _snapshotVersion;
    loading = true;
    loadFailed = false;
    notifyListeners();
    try {
      final devices = await repository.list();
      if (_disposed || version != _loadVersion) return;
      if (snapshotVersion == _snapshotVersion) {
        _devices = devices
            .where((device) => !_removed.contains(device.id))
            .map(_freshStatus)
            .toList();
      }
    } catch (_) {
      if (_disposed || version != _loadVersion) return;
      loadFailed = _snapshotVersion == snapshotVersion;
    }
    loading = false;
    notifyListeners();
  }

  Device _freshStatus(Device device) {
    final update = _statuses[device.id];
    if (update != null &&
        (device.checkedAt == null ||
            !device.checkedAt!.isAfter(update.checkedAt)) &&
        !(device.checkedAt == update.checkedAt &&
            device.sshCheckedAt != null &&
            (update.sshCheckedAt == null ||
                device.sshCheckedAt!.isAfter(update.sshCheckedAt!)))) {
      return device.withStatus(
        update.status,
        update.checkedAt,
        sshStatus: update.sshStatus,
        sshCheckedAt: update.sshCheckedAt,
      );
    }
    return device;
  }

  void _event(ComputerEvent event) {
    if (_disposed) return;
    switch (event) {
      case ComputerConnectionChanged():
        liveConnected = event.connected;
      case ComputerSnapshot():
        _snapshotVersion++;
        final visible = event.computers
            .where((item) => !_deletedLocally.contains(item.id))
            .toList();
        final ids = visible.map((item) => item.id).toSet();
        _removed.addAll(
          _devices.map((item) => item.id).where((id) => !ids.contains(id)),
        );
        _removed.removeAll(ids);
        // Snapshots are ordered with status frames on the same socket.
        // They also carry deliberate SSH resets after configuration changes.
        _statuses.clear();
        _devices = visible;
        loading = false;
        loadFailed = false;
      case ComputerStatusChanged():
        final index = _devices.indexWhere((device) => device.id == event.id);
        if (index < 0 || _removed.contains(event.id)) return;
        final previous = _statuses[event.id];
        if (previous != null &&
            (previous.checkedAt.isAfter(event.checkedAt) ||
                (previous.checkedAt == event.checkedAt &&
                    previous.sshCheckedAt != null &&
                    (event.sshCheckedAt == null ||
                        previous.sshCheckedAt!.isAfter(
                          event.sshCheckedAt!,
                        ))))) {
          return;
        }
        _statuses[event.id] = event;
        _devices[index] = _freshStatus(_devices[index]);
    }
    notifyListeners();
  }

  Future<void> checkSsh(String id) async {
    if (busy) return;
    final checker = repository;
    if (checker is! SshCheckRepository) return;
    checkingId = id;
    notifyListeners();
    try {
      final result = await (checker as SshCheckRepository).checkSsh(id);
      if (!_disposed) _event(result);
    } finally {
      checkingId = null;
      if (!_disposed) notifyListeners();
    }
  }

  void setFormOpen(bool value) {
    formOpen = value;
    notifyListeners();
  }

  void setDeleting(String? id) {
    deletingId = id;
    notifyListeners();
  }

  void setPowering(String? id) {
    poweringId = id;
    notifyListeners();
  }

  void applySaved(Device device) {
    // Registration may already have arrived in a live snapshot, with newer status.
    if (_removed.contains(device.id) ||
        _devices.any((item) => item.id == device.id)) {
      return;
    }
    _devices.add(_freshStatus(device));
    notifyListeners();
  }

  void applyUpdated(Device device) {
    if (_removed.contains(device.id)) return;
    final index = _devices.indexWhere((item) => item.id == device.id);
    if (index < 0) return;
    // Invalidate a list that started before this mutation.
    _loadVersion++;
    _statuses.remove(device.id);
    _devices[index] = device;
    notifyListeners();
  }

  void removeDevice(String id) {
    _deletedLocally.add(id);
    _removed.add(id);
    _statuses.remove(id);
    _devices.removeWhere((device) => device.id == id);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
