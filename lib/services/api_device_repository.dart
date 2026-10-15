import '../models/device.dart';
import '../models/computer_event.dart';
import 'computer_events.dart';
import '../models/device_registration.dart';
import 'api_service.dart';
import 'device_repository.dart';

class ApiDeviceRepository
    implements
        DeviceRepository,
        LiveDeviceRepository,
        SshCheckRepository,
        EditableDeviceRepository {
  ApiDeviceRepository(this.api, {Stream<ComputerEvent>? updates}) {
    if (updates == null) _events = ComputerEvents(api);
    _updates = updates ?? _events!.stream;
  }
  ComputerEvents? _events;
  late final Stream<ComputerEvent> _updates;
  @override
  Stream<ComputerEvent> get updates => _updates;
  void dispose() => _events?.dispose();
  final ApiService api;

  @override
  Future<List<Device>> list() async {
    final response = await api.get('/computers');
    if (response is! Map<String, dynamic> || response['computers'] is! List) {
      throw const FormatException('Expected a computers list.');
    }
    return (response['computers'] as List).map(_device).toList();
  }

  @override
  Future<Device> create(DeviceRegistration registration) async {
    final response = await api.request(
      'POST',
      '/computers',
      body: registration.toJson(),
    );
    if (response.statusCode != 201 || response.data is! Map<String, dynamic>) {
      throw const FormatException('Expected a registered computer.');
    }
    return _device((response.data as Map<String, dynamic>)['computer']);
  }

  @override
  Future<void> delete(String id) async {
    await api.delete('/computers/${Uri.encodeComponent(id)}');
  }

  @override
  Future<void> powerOn(String id) => _power(id, 'on');
  @override
  Future<void> powerOff(String id) => _power(id, 'off');

  @override
  Future<ComputerStatusChanged> checkSsh(String id) async {
    final response = await api.request(
      'POST',
      '/computers/${Uri.encodeComponent(id)}/check-ssh',
    );
    if (response.statusCode != 200 || response.data is! Map<String, dynamic>) {
      throw const FormatException('Invalid SSH check response.');
    }
    final result = ComputerStatusChanged.fromJson(
      response.data as Map<String, dynamic>,
    );
    if (result.id != id) throw const FormatException('Unexpected computer ID.');
    return result;
  }

  @override
  Future<Device> update(String id, Map<String, dynamic> changes) async {
    final response = await api.request(
      'PATCH',
      '/computers/${Uri.encodeComponent(id)}',
      body: changes,
    );
    if (response.statusCode != 200 || response.data is! Map<String, dynamic>) {
      throw const FormatException('Expected an updated computer.');
    }
    final device = _device((response.data as Map<String, dynamic>)['computer']);
    if (device.id != id) throw const FormatException('Unexpected computer ID.');
    return device;
  }

  Future<void> _power(String id, String action) async {
    final response = await api.request(
      'POST',
      '/computers/${Uri.encodeComponent(id)}/$action',
    );
    if (response.statusCode != 202 ||
        response.data is! Map ||
        (response.data as Map)['ok'] != true) {
      throw const FormatException('Power action was not confirmed.');
    }
  }
}

Device _device(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Invalid computer.');
  }
  return Device.fromJson(value);
}
