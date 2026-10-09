import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../network/token_storage.dart';
import '../utils/json.dart';
import 'server_clock.dart';

enum ConnectionStatus { disconnected, connecting, connected }

typedef MessageHandler = void Function(Json message);

/// The app's single STOMP-over-WebSocket connection, shared by every feature.
///
/// * Lazily connects on first use and authenticates with the stored JWT.
/// * Reconnects with exponential backoff (1 s → 30 s, with jitter).
/// * Keeps one server subscription per destination and fans messages out to
///   every local listener; subscriptions are restored after a reconnect.
/// * Buffers a few outgoing frames while offline and flushes them on reconnect.
/// * Feeds `serverTime` fields into [clock].
class RealtimeClient {
  RealtimeClient({
    required String url,
    required TokenStorage tokens,
    ServerClock? clock,
    StompClient Function(StompConfig config)? clientFactory,
  })  : _url = url,
        _tokens = tokens,
        clock = clock ?? ServerClock(),
        _factory = clientFactory ?? ((config) => StompClient(config: config));

  static const _maxQueued = 50;
  static const _heartbeat = Duration(seconds: 10);

  final String _url;
  final TokenStorage _tokens;
  final StompClient Function(StompConfig config) _factory;
  final ServerClock clock;

  StompClient? _client;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  final Map<String, _Topic> _topics = {};
  final List<(String, String?)> _queue = [];
  Timer? _retryTimer;
  int _attempt = 0;
  bool _wanted = false;
  final _random = Random();

  ConnectionStatus get status => _status;
  Stream<ConnectionStatus> get statusChanges => _statusController.stream;
  bool get isConnected => _status == ConnectionStatus.connected;

  /// Opens the connection (no-op if already open or opening).
  void connect() {
    _wanted = true;
    if (_status != ConnectionStatus.disconnected) return;
    unawaited(_open());
  }

  /// Closes the connection and forgets everything (used on sign-out).
  void disconnect() {
    _wanted = false;
    _retryTimer?.cancel();
    _client?.deactivate();
    _client = null;
    _queue.clear();
    for (final t in _topics.values) {
      t.unsubscribe = null;
    }
    _setStatus(ConnectionStatus.disconnected);
  }

  /// Listens to [destination]. Call [RealtimeSubscription.cancel] when done.
  RealtimeSubscription subscribe(String destination, MessageHandler onMessage) {
    connect();
    final topic = _topics.putIfAbsent(destination, () => _Topic(destination));
    final listener = _Listener(onMessage);
    topic.listeners.add(listener);
    if (isConnected && topic.unsubscribe == null) _serverSubscribe(topic);
    return RealtimeSubscription._(() {
      topic.listeners.remove(listener);
      if (topic.listeners.isEmpty) {
        _topics.remove(destination);
        try {
          topic.unsubscribe?.call();
        } catch (_) {
          // Connection already gone; nothing to unsubscribe.
        }
      }
    });
  }

  /// Sends a JSON body to an application destination (e.g. `/app/room/x/join`).
  void send(String destination, [Object? body]) {
    final encoded = body == null ? null : jsonEncode(body);
    final client = _client;
    if (isConnected && client != null) {
      client.send(destination: destination, body: encoded ?? '');
    } else {
      if (_queue.length >= _maxQueued) _queue.removeAt(0);
      _queue.add((destination, encoded));
      connect();
    }
  }

  Future<void> _open() async {
    _setStatus(ConnectionStatus.connecting);
    final token = await _tokens.read();
    if (!_wanted) return;
    if (token == null) {
      _setStatus(ConnectionStatus.disconnected);
      return;
    }
    final headers = {'Authorization': 'Bearer $token'};
    final client = _factory(StompConfig(
      url: _url,
      // Reconnection is handled here, with backoff and a fresh token each time.
      reconnectDelay: Duration.zero,
      heartbeatIncoming: _heartbeat,
      heartbeatOutgoing: _heartbeat,
      connectionTimeout: const Duration(seconds: 10),
      stompConnectHeaders: headers,
      webSocketConnectHeaders: headers,
      onConnect: (_) => _onConnected(),
      onWebSocketDone: _onLost,
      onWebSocketError: (_) => _onLost(),
      onStompError: (frame) {
        debugPrint('[realtime] STOMP error: ${frame.body}');
        _onLost();
      },
    ));
    _client = client;
    client.activate();
  }

  void _onConnected() {
    _attempt = 0;
    _setStatus(ConnectionStatus.connected);
    for (final topic in _topics.values) {
      _serverSubscribe(topic);
    }
    final pending = List.of(_queue);
    _queue.clear();
    for (final (destination, body) in pending) {
      _client?.send(destination: destination, body: body ?? '');
    }
  }

  void _onLost() {
    if (_client == null) return;
    _client?.deactivate();
    _client = null;
    for (final t in _topics.values) {
      t.unsubscribe = null;
    }
    _setStatus(ConnectionStatus.disconnected);
    if (!_wanted) return;
    _retryTimer?.cancel();
    final base = min(30000, 1000 * pow(2, _attempt).toInt());
    final delay = Duration(milliseconds: base ~/ 2 + _random.nextInt(base ~/ 2 + 1));
    _attempt = min(_attempt + 1, 6);
    _retryTimer = Timer(delay, () {
      if (_wanted && _status == ConnectionStatus.disconnected) unawaited(_open());
    });
  }

  void _serverSubscribe(_Topic topic) {
    final client = _client;
    if (client == null) return;
    topic.unsubscribe = client.subscribe(
      destination: topic.destination,
      callback: (frame) {
        final body = frame.body;
        if (body == null || body.isEmpty) return;
        final Object? decoded;
        try {
          decoded = jsonDecode(body);
        } catch (_) {
          return;
        }
        final message = asObj(decoded);
        final serverTime = message['serverTime'];
        if (serverTime is int) clock.sample(serverTime);
        for (final listener in List.of(topic.listeners)) {
          listener.handler(message);
        }
      },
    );
  }

  void _setStatus(ConnectionStatus status) {
    if (_status == status) return;
    _status = status;
    _statusController.add(status);
  }

  void dispose() {
    disconnect();
    _statusController.close();
  }
}

class RealtimeSubscription {
  RealtimeSubscription._(this._cancel);

  final void Function() _cancel;
  bool _cancelled = false;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _cancel();
  }
}

class _Topic {
  _Topic(this.destination);

  final String destination;
  final List<_Listener> listeners = [];
  StompUnsubscribe? unsubscribe;
}

class _Listener {
  _Listener(this.handler);

  final MessageHandler handler;
}
