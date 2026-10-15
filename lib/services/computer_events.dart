import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/computer_event.dart';
import '../models/device.dart';
import 'api_service.dart';

abstract interface class ComputerEventConnection {
  Stream<Object?> get messages;
  Future<void> close();
}

/// Owns one native status connection, reconnecting while the session is valid.
class ComputerEvents {
  ComputerEvents(
    this.api, {
    Future<ComputerEventConnection> Function()? connect,
    this.retryDelay = const Duration(seconds: 3),
  }) {
    _connectTransport =
        connect ??
        () async => _NativeConnection(await api.openWebSocket('/ws/computers'));
    api.session.addListener(_sessionChanged);
  }
  final ApiService api;
  final Duration retryDelay;
  late final Future<ComputerEventConnection> Function() _connectTransport;
  late final _events = StreamController<ComputerEvent>.broadcast(
    onListen: _connect,
  );
  Stream<ComputerEvent> get stream => _events.stream;
  ComputerEventConnection? _connection;
  StreamSubscription<Object?>? _subscription;
  Timer? _retry;
  bool _disposed = false, _connecting = false;

  Future<void> _connect() async {
    if (_disposed || _connecting || !api.session.isAuthenticated) return;
    _connecting = true;
    try {
      final connection = await _connectTransport();
      if (_disposed || !api.session.isAuthenticated) {
        await connection.close();
        return;
      }
      _connection = connection;
      _events.add(const ComputerConnectionChanged(true));
      _subscription = connection.messages.listen(
        _message,
        onError: (Object error) => _disconnected(),
        onDone: _disconnected,
      );
    } catch (_) {
      if (!_disposed) _disconnected();
    } finally {
      _connecting = false;
    }
  }

  void _message(Object? message) {
    if (_disposed) return;
    try {
      final data = jsonDecode(
        message is String ? message : utf8.decode(message as List<int>),
      );
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid event.');
      }
      switch (data['type']) {
        case 'snapshot':
          final items = data['computers'];
          if (items is! List) throw const FormatException('Invalid snapshot.');
          _events.add(
            ComputerSnapshot(
              items
                  .map(
                    (item) =>
                        Device.fromJson(Map<String, dynamic>.from(item as Map)),
                  )
                  .toList(),
            ),
          );
        case 'status':
          final id = data['computerId'], checkedAt = data['checkedAt'];
          if (id is! String || checkedAt is! String) {
            throw const FormatException('Invalid status.');
          }
          _events.add(ComputerStatusChanged.fromJson(data));
      }
    } catch (_) {
      _disconnected(); // Obtain a fresh snapshot rather than retain malformed state.
    }
  }

  void _closeConnection() {
    final subscription = _subscription, connection = _connection;
    _subscription = null;
    _connection = null;
    if (subscription != null) unawaited(subscription.cancel());
    if (connection != null) {
      unawaited(connection.close().catchError((Object _) {}));
    }
  }

  void _disconnected() {
    if (_disposed) return;
    _closeConnection();
    _events.add(const ComputerConnectionChanged(false));
    if (api.session.isAuthenticated && _retry == null) {
      _retry = Timer(retryDelay, () {
        _retry = null;
        unawaited(_connect());
      });
    }
  }

  void _sessionChanged() {
    if (!api.session.isAuthenticated) {
      _retry?.cancel();
      _retry = null;
      _closeConnection();
    }
  }

  void dispose() {
    _disposed = true;
    api.session.removeListener(_sessionChanged);
    _retry?.cancel();
    _closeConnection();
    unawaited(_events.close());
  }
}

class _NativeConnection implements ComputerEventConnection {
  _NativeConnection(this.socket);
  final WebSocket socket;
  @override
  Stream<Object?> get messages => socket;
  @override
  Future<void> close() async {
    await socket.close();
  }
}
