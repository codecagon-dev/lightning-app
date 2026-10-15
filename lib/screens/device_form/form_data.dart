import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/device.dart';
import '../../models/device_registration.dart';
import '../../validation/device_validators.dart';

class DeviceFormData {
  DeviceFormData({this.original}) {
    final device = original;
    if (device == null) return;
    name.text = device.name;
    mac.text = device.macAddress;
    ip.text = device.ipAddress;
    broadcast.text = device.broadcastAddress;
    wolPort.text = '${device.wolPort}';
    sshPort.text = '${device.sshPort}';
    username.text = device.sshUsername;
    fingerprint.text = device.sshHostKeyFingerprint;
    color = device.color;
    os = device.os;
  }
  final Device? original;
  bool replaceCredentials = false;
  bool get needsCredentials => original == null || replaceCredentials;

  Map<String, dynamic> toPatch() {
    final device = original!;
    final values = <String, dynamic>{
      'name': name.text.trim(),
      'macAddress': DeviceValidators.normalizeMac(mac.text).toLowerCase(),
      'ipAddress': ip.text.trim(),
      'broadcastAddress': broadcast.text.trim(),
      'wolPort': int.parse(wolPort.text),
      'sshPort': int.parse(sshPort.text),
      'sshUsername': username.text.trim(),
      'sshHostKeyFingerprint': fingerprint.text.trim(),
      'color': color == null
          ? null
          : '#${color!.toRadixString(16).padLeft(6, '0')}',
      'os': os.name,
    };
    final previous = <String, dynamic>{
      'name': device.name,
      'macAddress': device.macAddress.toLowerCase(),
      'ipAddress': device.ipAddress,
      'broadcastAddress': device.broadcastAddress,
      'wolPort': device.wolPort,
      'sshPort': device.sshPort,
      'sshUsername': device.sshUsername,
      'sshHostKeyFingerprint': device.sshHostKeyFingerprint,
      'color': device.color == null
          ? null
          : '#${device.color!.toRadixString(16).padLeft(6, '0')}',
      'os': device.os.name,
    };
    values.removeWhere((key, value) => value == previous[key]);
    if (replaceCredentials) {
      if (authType == SshAuthType.password) {
        values['sshPassword'] = password.text;
      } else {
        values['sshPrivateKey'] = privateKey.text;
        if (passphrase.text.isNotEmpty) {
          values['sshPrivateKeyPassphrase'] = passphrase.text;
        }
      }
    }
    return values;
  }

  final name = TextEditingController();
  final mac = TextEditingController();
  final ip = TextEditingController();
  final broadcast = TextEditingController();
  final wolPort = TextEditingController(text: '9');
  final sshPort = TextEditingController(text: '22');
  final username = TextEditingController();
  final fingerprint = TextEditingController();
  final password = TextEditingController();
  final privateKey = TextEditingController();
  final passphrase = TextEditingController();
  int? color;
  DeviceOs os = DeviceOs.linux;
  SshAuthType authType = SshAuthType.password;

  void dispose() {
    for (final controller in [
      name,
      mac,
      ip,
      broadcast,
      wolPort,
      sshPort,
      username,
      fingerprint,
      password,
      privateKey,
      passphrase,
    ]) {
      controller.dispose();
    }
  }

  DeviceRegistration toRegistration() => DeviceRegistration(
    name: name.text.trim(),
    macAddress: DeviceValidators.normalizeMac(mac.text),
    ipAddress: ip.text.trim(),
    broadcastAddress: broadcast.text.trim(),
    wolPort: int.parse(wolPort.text),
    os: os,
    color: color,
    ssh: SshConfig(
      port: int.parse(sshPort.text),
      username: username.text.trim(),
      hostKeyFingerprint: fingerprint.text.trim(),
      authType: authType,
      password: authType == SshAuthType.password ? password.text : null,
      privateKey: authType == SshAuthType.privateKey ? privateKey.text : null,
      passphrase:
          authType == SshAuthType.privateKey && passphrase.text.isNotEmpty
          ? passphrase.text
          : null,
    ),
  );

  DeviceValidationError? get validationError =>
      DeviceValidators.name(name.text) ??
      DeviceValidators.macAddress(mac.text) ??
      DeviceValidators.ipv4(ip.text) ??
      DeviceValidators.ipv4(broadcast.text) ??
      DeviceValidators.port(wolPort.text) ??
      DeviceValidators.port(sshPort.text) ??
      DeviceValidators.username(username.text) ??
      DeviceValidators.fingerprint(fingerprint.text) ??
      (needsCredentials
          ? DeviceValidators.credential(
              authType == SshAuthType.password
                  ? password.text
                  : privateKey.text,
            )
          : null) ??
      (needsCredentials && credentialsTooLarge
          ? DeviceValidationError.credentialsTooLarge
          : null);

  bool get credentialsTooLarge {
    final credentials = authType == SshAuthType.password
        ? {'sshPassword': password.text}
        : {
            'sshPrivateKey': privateKey.text,
            if (passphrase.text.isNotEmpty)
              'sshPrivateKeyPassphrase': passphrase.text,
          };
    return utf8.encode(jsonEncode(credentials)).length > 32768;
  }
}
