import 'package:flutter_test/flutter_test.dart';
import 'package:lightning/validation/device_validators.dart';
import 'package:lightning/screens/device_form/form_data.dart';
import 'package:lightning/models/device.dart';

import '../fixtures/computer.dart';

void main() {
  test(
    'editing sends only changed fields and preserves hidden credentials',
    () {
      final data = DeviceFormData(
        original: Device.fromJson({...computerJson, 'color': '#3366ff'}),
      );
      expect(data.validationError, isNull);
      expect(data.toPatch(), isEmpty);
      data.name.text = 'Gaming-pc';
      data.color = null;
      expect(data.toPatch(), {'name': 'Gaming-pc', 'color': null});
      data.replaceCredentials = true;
      expect(data.validationError, DeviceValidationError.requiredText);
      data.password.text = ' replacement ';
      expect(data.toPatch()['sshPassword'], ' replacement ');
      data.authType = SshAuthType.privateKey;
      data.privateKey.text = 'private key';
      data.passphrase.text = ' secret ';
      expect(data.toPatch()['sshPassword'], isNull);
      expect(data.toPatch()['sshPrivateKeyPassphrase'], ' secret ');
      data.replaceCredentials = false;
      expect(data.toPatch(), {'name': 'Gaming-pc', 'color': null});
      data.dispose();
    },
  );

  test('validates canonical host fingerprints and strict IPv4', () {
    expect(
      DeviceValidators.fingerprint(
        'SHA256:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
      ),
      isNull,
    );
    expect(
      DeviceValidators.fingerprint(
        'SHA256:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB',
      ),
      DeviceValidationError.invalidFingerprint,
    );
    expect(
      DeviceValidators.fingerprint(
        'SHA256:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
      ),
      DeviceValidationError.invalidFingerprint,
    );
    expect(DeviceValidators.ipv4('192.168.1.255'), isNull);
    expect(
      DeviceValidators.ipv4('192.168.001.20'),
      DeviceValidationError.invalidIp,
    );
    expect(DeviceValidators.name('n' * 100), isNull);
    expect(DeviceValidators.name('n' * 101), DeviceValidationError.nameTooLong);
  });
  test('credential limit counts UTF-8 and JSON escaping together', () {
    final data = DeviceFormData();
    data.password.text = 'é' * 17000;
    expect(data.credentialsTooLarge, isTrue);
    data.password.text = '\\' * 17000;
    expect(data.credentialsTooLarge, isTrue);
    data.authType = SshAuthType.privateKey;
    data.privateKey.text = 'key';
    data.passphrase.text = 'passphrase';
    expect(data.credentialsTooLarge, isFalse);
    expect(
      DeviceValidators.privateKey(
        '-----BEGIN ENCRYPTED PRIVATE KEY-----\nabc\n-----END ENCRYPTED PRIVATE KEY-----',
      ),
      isNull,
    );
    data.dispose();
  });
}
