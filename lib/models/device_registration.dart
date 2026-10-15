import 'device.dart';

/// One request's registration input; never retained in the devices list.
class DeviceRegistration {
  const DeviceRegistration({
    required this.name,
    required this.macAddress,
    required this.ipAddress,
    required this.broadcastAddress,
    required this.wolPort,
    required this.ssh,
    this.os = DeviceOs.linux,
    this.color,
  });
  final String name, macAddress, ipAddress, broadcastAddress;
  final int wolPort;
  final DeviceOs os;
  final int? color;
  final SshConfig ssh;

  Map<String, dynamic> toJson() => {
    'name': name,
    'macAddress': macAddress.toLowerCase(),
    'ipAddress': ipAddress,
    'broadcastAddress': broadcastAddress,
    'wolPort': wolPort,
    'os': os.name,
    'color': color == null
        ? null
        : '#${color!.toRadixString(16).padLeft(6, '0')}',
    'sshPort': ssh.port,
    'sshUsername': ssh.username,
    'sshHostKeyFingerprint': ssh.hostKeyFingerprint,
    if (ssh.authType == SshAuthType.password) 'sshPassword': ssh.password,
    if (ssh.authType == SshAuthType.privateKey) 'sshPrivateKey': ssh.privateKey,
    if (ssh.authType == SshAuthType.privateKey && ssh.passphrase != null)
      'sshPrivateKeyPassphrase': ssh.passphrase,
  };

  Device toPublicDevice(String id) => Device(
    id: id,
    name: name,
    macAddress: macAddress.toLowerCase(),
    ipAddress: ipAddress,
    broadcastAddress: broadcastAddress,
    wolPort: wolPort,
    os: os,
    color: color,
    sshPort: ssh.port,
    sshUsername: ssh.username,
    sshHostKeyFingerprint: ssh.hostKeyFingerprint,
    createdAt: DateTime.now().toUtc(),
  );
}

class SshConfig {
  SshConfig({
    required this.port,
    required this.username,
    required this.hostKeyFingerprint,
    required this.authType,
    this.password,
    this.privateKey,
    this.passphrase,
  }) {
    if (authType == SshAuthType.password) {
      if (password == null ||
          password!.isEmpty ||
          privateKey != null ||
          passphrase != null) {
        throw ArgumentError(
          'Password authentication requires only a password.',
        );
      }
    } else if (privateKey == null || privateKey!.isEmpty || password != null) {
      throw ArgumentError(
        'Private-key authentication requires only a key and optional passphrase.',
      );
    }
  }
  final int port;
  final String username, hostKeyFingerprint;
  final SshAuthType authType;
  final String? password, privateKey, passphrase;
}
