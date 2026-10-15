enum DeviceOs { linux, windows }

enum DeviceStatus { unknown, online, offline }

enum SshStatus {
  unknown,
  ready,
  authFailed,
  hostKeyMismatch,
  unreachable,
  error,
}

enum SshAuthType { password, privateKey }

/// Public computer data. SSH credentials are deliberately not stored here.
class Device {
  const Device({
    required this.id,
    required this.name,
    required this.macAddress,
    required this.ipAddress,
    required this.broadcastAddress,
    required this.wolPort,
    required this.sshPort,
    required this.sshUsername,
    required this.sshHostKeyFingerprint,
    this.os = DeviceOs.linux,
    this.color,
    this.status = DeviceStatus.unknown,
    this.createdAt,
    this.checkedAt,
    this.sshStatus = SshStatus.unknown,
    this.sshCheckedAt,
  });

  final String id, name, macAddress, ipAddress, broadcastAddress;
  final int wolPort, sshPort;
  final String sshUsername, sshHostKeyFingerprint;
  final DeviceOs os;
  final int? color;
  final DeviceStatus status;
  final DateTime? createdAt, checkedAt;
  final SshStatus sshStatus;
  final DateTime? sshCheckedAt;

  factory Device.fromJson(Map<String, dynamic> json) {
    final rawColor = json['color'];
    if (rawColor != null &&
        (rawColor is! String ||
            !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(rawColor))) {
      throw const FormatException('Invalid computer color.');
    }
    return Device(
      id: _string(json, 'id'),
      name: _string(json, 'name'),
      macAddress: _string(json, 'macAddress'),
      ipAddress: _string(json, 'ipAddress'),
      broadcastAddress: _string(json, 'broadcastAddress'),
      wolPort: _integer(json, 'wolPort'),
      sshPort: _integer(json, 'sshPort'),
      sshUsername: _string(json, 'sshUsername'),
      sshHostKeyFingerprint: _string(json, 'sshHostKeyFingerprint'),
      os: switch (json['os']) {
        'linux' => DeviceOs.linux,
        'windows' => DeviceOs.windows,
        _ => throw const FormatException('Invalid computer OS.'),
      },
      color: rawColor == null
          ? null
          : int.parse((rawColor as String).substring(1), radix: 16),
      status: parseStatus(json['status']),
      createdAt: _date(json['createdAt']),
      checkedAt: _date(json['checkedAt']),
      sshStatus: parseSshStatus(json['sshStatus']),
      sshCheckedAt: _date(json['sshCheckedAt']),
    );
  }

  static DeviceStatus parseStatus(Object? value) => switch (value) {
    'unknown' => DeviceStatus.unknown,
    'online' => DeviceStatus.online,
    'offline' => DeviceStatus.offline,
    _ => throw const FormatException('Invalid computer status.'),
  };

  static SshStatus parseSshStatus(Object? value) => switch (value) {
    null || 'unknown' => SshStatus.unknown,
    'ready' => SshStatus.ready,
    'auth_failed' => SshStatus.authFailed,
    'host_key_mismatch' => SshStatus.hostKeyMismatch,
    'unreachable' => SshStatus.unreachable,
    'error' => SshStatus.error,
    _ => throw const FormatException('Invalid SSH status.'),
  };

  Device withStatus(
    DeviceStatus value,
    DateTime? timestamp, {
    SshStatus? sshStatus,
    DateTime? sshCheckedAt,
  }) => Device(
    id: id,
    name: name,
    macAddress: macAddress,
    ipAddress: ipAddress,
    broadcastAddress: broadcastAddress,
    wolPort: wolPort,
    sshPort: sshPort,
    sshUsername: sshUsername,
    sshHostKeyFingerprint: sshHostKeyFingerprint,
    os: os,
    color: color,
    createdAt: createdAt,
    status: value,
    checkedAt: timestamp,
    sshStatus: sshStatus ?? this.sshStatus,
    sshCheckedAt: sshStatus == null ? this.sshCheckedAt : sshCheckedAt,
  );
}

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException('Invalid computer $key.');
}

int _integer(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  throw FormatException('Invalid computer $key.');
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  if (value is String) return DateTime.parse(value);
  throw const FormatException('Invalid computer timestamp.');
}
