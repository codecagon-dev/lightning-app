import '../models/device.dart';
import '../models/computer_event.dart';
import '../models/device_registration.dart';

abstract interface class DeviceRepository {
  Future<List<Device>> list();
  Future<Device> create(DeviceRegistration registration);
  Future<void> delete(String id);
  Future<void> powerOn(String id);
  Future<void> powerOff(String id);
}

abstract interface class EditableDeviceRepository {
  Future<Device> update(String id, Map<String, dynamic> changes);
}

abstract interface class SshCheckRepository {
  Future<ComputerStatusChanged> checkSsh(String id);
}

abstract interface class LiveDeviceRepository {
  Stream<ComputerEvent> get updates;
}

/// Local preview/test repository; the configured app uses ApiDeviceRepository.
class MemoryDeviceRepository implements DeviceRepository {
  final Map<String, Device> _devices = {};
  int _nextId = 1;

  @override
  Future<List<Device>> list() async => List.unmodifiable(_devices.values);
  @override
  Future<Device> create(DeviceRegistration registration) async {
    final device = registration.toPublicDevice('device-${_nextId++}');
    _devices[device.id] = device;
    return device;
  }

  @override
  Future<void> delete(String id) async {
    if (_devices.remove(id) == null) throw StateError('Device not found.');
  }

  @override
  Future<void> powerOn(String id) async =>
      throw UnsupportedError('No hardware API configured.');
  @override
  Future<void> powerOff(String id) async =>
      throw UnsupportedError('No hardware API configured.');
}
