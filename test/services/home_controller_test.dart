import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lightning/models/computer_event.dart';
import 'package:lightning/models/device.dart';
import 'package:lightning/models/device_registration.dart';
import 'package:lightning/services/device_repository.dart';
import 'package:lightning/screens/home/home_controller.dart';

import '../fixtures/computer.dart';

class DeferredRepository implements DeviceRepository, SshCheckRepository {
  final sshResult = Completer<ComputerStatusChanged>();
  @override
  Future<ComputerStatusChanged> checkSsh(String id) => sshResult.future;
  final result = Completer<List<Device>>();
  @override
  Future<List<Device>> list() => result.future;
  @override
  Future<Device> create(DeviceRegistration registration) async =>
      registration.toPublicDevice('c1');
  @override
  Future<void> delete(String id) async {}
  @override
  Future<void> powerOn(String id) async {}
  @override
  Future<void> powerOff(String id) async {}
}

void main() {
  test('manual SSH failures release the loading guard', () async {
    final repository = DeferredRepository();
    final controller = HomeController(repository);
    repository.result.complete([Device.fromJson(computerJson)]);
    await controller.load();
    final checking = controller.checkSsh('c1');
    expect(controller.checkingId, 'c1');
    expect(controller.busy, isTrue);
    final failure = expectLater(checking, throwsStateError);
    repository.sshResult.completeError(StateError('Unavailable'));
    await failure;
    expect(controller.checkingId, isNull);
    expect(controller.busy, isFalse);
    expect(controller.devices.single.sshStatus, SshStatus.unknown);
    controller.dispose();
  });

  test('SSH-only updates apply when TCP timestamp has not changed', () async {
    final events = StreamController<ComputerEvent>(sync: true);
    final controller = HomeController(
      MemoryDeviceRepository(),
      updates: events.stream,
    );
    final checked = DateTime.utc(2026, 10, 15, 12);
    events.add(ComputerSnapshot([Device.fromJson(computerJson)]));
    events.add(ComputerStatusChanged('c1', DeviceStatus.online, checked));
    events.add(
      ComputerStatusChanged(
        'c1',
        DeviceStatus.online,
        checked,
        sshStatus: SshStatus.ready,
        sshCheckedAt: checked.add(const Duration(seconds: 2)),
      ),
    );
    expect(controller.devices.single.sshStatus, SshStatus.ready);
    expect(
      controller.devices.single.sshCheckedAt,
      checked.add(const Duration(seconds: 2)),
    );
    events.add(ComputerSnapshot([Device.fromJson(computerJson)]));
    expect(controller.devices.single.sshStatus, SshStatus.unknown);
    events.add(
      ComputerStatusChanged(
        'c1',
        DeviceStatus.offline,
        checked.add(const Duration(seconds: 10)),
        sshStatus: SshStatus.unreachable,
        sshCheckedAt: checked.add(const Duration(seconds: 2)),
      ),
    );
    expect(controller.devices.single.sshStatus, SshStatus.unreachable);
    controller.dispose();
    await events.close();
  });

  test(
    'a queued pre-delete snapshot cannot restore a locally deleted device',
    () async {
      final events = StreamController<ComputerEvent>(sync: true);
      final controller = HomeController(
        MemoryDeviceRepository(),
        updates: events.stream,
      );
      final device = Device.fromJson(computerJson);
      events.add(ComputerSnapshot([device]));
      controller.removeDevice('c1');
      events.add(ComputerSnapshot([device]));
      expect(controller.devices, isEmpty);
      controller.dispose();
      await events.close();
    },
  );

  test('live snapshot wins over an older in-flight HTTP list', () async {
    final repository = DeferredRepository();
    final events = StreamController<ComputerEvent>(sync: true);
    final controller = HomeController(repository, updates: events.stream);
    final loading = controller.load();
    final live = Device.fromJson({
      ...computerJson,
      'status': 'online',
      'checkedAt': '2026-10-15T12:01:00Z',
    });
    events.add(ComputerSnapshot([live]));
    repository.result.complete([Device.fromJson(computerJson)]);
    await loading;
    expect(controller.devices.single.status, DeviceStatus.online);
    expect(controller.loadFailed, isFalse);
    controller.dispose();
    await events.close();
  });

  test('a create response never overwrites a newer pushed status or resurrects a deletion', () async {
    final events = StreamController<ComputerEvent>(sync: true);
    final controller = HomeController(
      MemoryDeviceRepository(),
      updates: events.stream,
    );
    events.add(ComputerSnapshot([Device.fromJson(computerJson)]));
    events.add(
      ComputerStatusChanged(
        'c1',
        DeviceStatus.online,
        DateTime.utc(2026, 10, 15, 12, 1),
      ),
    );
    controller.applySaved(Device.fromJson(computerJson));
    expect(controller.devices.single.status, DeviceStatus.online);
    events.add(ComputerSnapshot([]));
    events.add(
      ComputerStatusChanged(
        'c1',
        DeviceStatus.offline,
        DateTime.utc(2026, 10, 15, 12, 2),
      ),
    );
    controller.applySaved(Device.fromJson(computerJson));
    expect(controller.devices, isEmpty);
    controller.dispose();
    await events.close();
  });
}
