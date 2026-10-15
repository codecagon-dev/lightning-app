import 'dart:convert';

enum DeviceValidationError {
  nameRequired,
  nameTooLong,
  invalidMac,
  invalidIp,
  invalidPort,
  invalidSubnet,
  nonContiguousSubnet,
  requiredText,
  privateKeyRequired,
  encryptedPrivateKey,
  invalidPrivateKey,
  invalidFingerprint,
  textTooLong,
  credentialsTooLarge,
}

class DeviceValidators {
  static DeviceValidationError? name(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return DeviceValidationError.nameRequired;
    if (text.length > 100) return DeviceValidationError.nameTooLong;
    return null;
  }

  static DeviceValidationError? macAddress(String? value) {
    final text = value?.trim() ?? '';
    final compact =
        RegExp(r'^[0-9A-Fa-f]{12}$').hasMatch(text) ||
        RegExp(r'^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}$').hasMatch(text) ||
        RegExp(r'^[0-9A-Fa-f]{2}(-[0-9A-Fa-f]{2}){5}$').hasMatch(text);
    if (!compact) {
      return DeviceValidationError.invalidMac;
    }
    return null;
  }

  static String normalizeMac(String value) {
    if (macAddress(value) != null) {
      throw FormatException('Invalid MAC address.');
    }
    final compact = value.trim().replaceAll(RegExp(r'[:-]'), '').toUpperCase();
    return List.generate(
      6,
      (i) => compact.substring(i * 2, i * 2 + 2),
    ).join(':');
  }

  static DeviceValidationError? ipAddress(String? value) {
    final octets = _parseIpv4(value);
    if (octets == null ||
        (octets.every((octet) => octet == 0)) ||
        (octets.every((octet) => octet == 255))) {
      return DeviceValidationError.invalidIp;
    }
    return null;
  }

  static DeviceValidationError? port(String? value) {
    final text = value?.trim() ?? '';
    final parsed = int.tryParse(text);
    if (!RegExp(r'^[0-9]+$').hasMatch(text) ||
        parsed == null ||
        parsed < 1 ||
        parsed > 65535) {
      return DeviceValidationError.invalidPort;
    }
    return null;
  }

  static DeviceValidationError? subnetMask(String? value) {
    final octets = _parseIpv4(value);
    if (octets == null) return DeviceValidationError.invalidSubnet;
    final bits = octets
        .map((octet) => octet.toRadixString(2).padLeft(8, '0'))
        .join();
    if (!RegExp(r'^1{1,32}0*$').hasMatch(bits)) {
      return DeviceValidationError.nonContiguousSubnet;
    }
    return null;
  }

  static DeviceValidationError? requiredText(String? value) =>
      value == null || value.trim().isEmpty
      ? DeviceValidationError.requiredText
      : null;

  static DeviceValidationError? username(String? value) {
    if (requiredText(value) != null) return DeviceValidationError.requiredText;
    return value!.trim().length > 128
        ? DeviceValidationError.textTooLong
        : null;
  }

  static DeviceValidationError? fingerprint(String? value) {
    final text = value?.trim() ?? '';
    if (!RegExp(r'^SHA256:[A-Za-z0-9+/]{43}$').hasMatch(text)) {
      return DeviceValidationError.invalidFingerprint;
    }
    try {
      final decoded = base64Decode('${text.substring(7)}=');
      if (decoded.length == 32 &&
          base64Encode(decoded).replaceAll('=', '') == text.substring(7)) {
        return null;
      }
    } on FormatException {
      /* Return a field error below. */
    }
    return DeviceValidationError.invalidFingerprint;
  }

  static DeviceValidationError? privateKey(String? value) => credential(value);

  static DeviceValidationError? credential(String? value) {
    if (requiredText(value) != null) return DeviceValidationError.requiredText;
    return value!.length > 32768
        ? DeviceValidationError.credentialsTooLarge
        : null;
  }

  static DeviceValidationError? ipv4(String? value) =>
      _parseIpv4(value) == null ? DeviceValidationError.invalidIp : null;

  static List<int>? _parseIpv4(String? value) {
    final text = value?.trim() ?? '';
    final parts = text.split('.');
    if (parts.length != 4) return null;
    final octets = <int>[];
    for (final part in parts) {
      if (!RegExp(r'^(0|[1-9][0-9]{0,2})$').hasMatch(part)) return null;
      final octet = int.tryParse(part);
      if (octet == null || octet > 255) return null;
      octets.add(octet);
    }
    return octets;
  }
}
