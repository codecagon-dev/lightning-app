import 'device.dart';

sealed class ComputerEvent {
  const ComputerEvent();
}

class ComputerSnapshot extends ComputerEvent {
  ComputerSnapshot(List<Device> computers)
    : computers = List.unmodifiable(computers);
  final List<Device> computers;
}

class ComputerStatusChanged extends ComputerEvent {
  const ComputerStatusChanged(
    this.id,
    this.status,
    this.checkedAt, {
    this.sshStatus = SshStatus.unknown,
    this.sshCheckedAt,
  });
  final String id;
  final DeviceStatus status;
  final DateTime checkedAt;
  final SshStatus sshStatus;
  final DateTime? sshCheckedAt;

  factory ComputerStatusChanged.fromJson(Map<String, dynamic> json) =>
      ComputerStatusChanged(
        json['computerId'] as String,
        Device.parseStatus(json['status']),
        DateTime.parse(json['checkedAt'] as String),
        sshStatus: Device.parseSshStatus(json['sshStatus']),
        sshCheckedAt: json['sshCheckedAt'] == null
            ? null
            : DateTime.parse(json['sshCheckedAt'] as String),
      );
}

class ComputerConnectionChanged extends ComputerEvent {
  const ComputerConnectionChanged(this.connected);
  final bool connected;
}
