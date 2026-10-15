import 'package:lightning/models/device.dart';
import 'package:lightning/models/device_registration.dart';

const computerJson = <String, dynamic>{
  'id': 'c1',
  'name': 'Workstation',
  'color': null,
  'os': 'linux',
  'ipAddress': '192.168.1.20',
  'macAddress': 'aa:bb:cc:dd:ee:ff',
  'broadcastAddress': '192.168.1.255',
  'sshPort': 22,
  'wolPort': 9,
  'sshUsername': 'lightning',
  'sshHostKeyFingerprint': 'SHA256:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
  'createdAt': '2026-10-15T12:00:00.000Z',
  'status': 'unknown',
  'checkedAt': null,
};

DeviceRegistration registration({bool key = false}) => DeviceRegistration(
  name: 'Workstation',
  macAddress: 'AA:BB:CC:DD:EE:FF',
  ipAddress: '192.168.1.20',
  broadcastAddress: '192.168.1.255',
  wolPort: 9,
  ssh: SshConfig(
    port: 22,
    username: 'lightning',
    hostKeyFingerprint: 'SHA256:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
    authType: key ? SshAuthType.privateKey : SshAuthType.password,
    password: key ? null : ' keep spaces ',
    privateKey: key ? 'encrypted-key' : null,
    passphrase: key ? ' secret phrase ' : null,
  ),
);
