import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

enum WebSocketEventType {
  connected,
  disconnected,
  message,
  error,
}

class WebSocketEvent {
  final WebSocketEventType type;
  final dynamic data;
  
  WebSocketEvent(this.type, this.data);
}

class WebSocketManager {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  bool _isConnected = false;
  bool _isConnecting = false;
  DateTime? _lastConnectionAttempt;
  
  final _controller = StreamController<WebSocketEvent>.broadcast();
  Stream<WebSocketEvent> get events => _controller.stream;
  
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  
  WebSocketManager() {
    print('🔄 WebSocketManager initialized');
  }
  
  Future<void> connect() async {
    if (_isConnecting) {
      print('⚠️  Already connecting WebSocket, skipping...');
      return;
    }
    
    final now = DateTime.now();
    if (_lastConnectionAttempt != null &&
        now.difference(_lastConnectionAttempt!) < const Duration(seconds: 3)) {
      print('⚠️  WebSocket connection attempt too soon, skipping...');
      return;
    }
    
    _lastConnectionAttempt = now;
    _isConnecting = true;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token == null || token.isEmpty) {
        print('❌ Token tidak tersedia untuk WebSocket');
        _isConnecting = false;
        return;
      }
      
      await _disconnect();
      
      final apiBaseUrl = dotenv.env['API_BASE_URL'];
      if (apiBaseUrl == null) {
        print('❌ API_BASE_URL tidak ditemukan di .env');
        _isConnecting = false;
        return;
      }
      
      String wsUrl;
      if (apiBaseUrl.startsWith('https://')) {
        wsUrl = apiBaseUrl.replaceFirst('https://', 'wss://');
      } else if (apiBaseUrl.startsWith('http://')) {
        wsUrl = apiBaseUrl.replaceFirst('http://', 'ws://');
      } else {
        wsUrl = 'ws://$apiBaseUrl';
      }
      
      if (wsUrl.endsWith('/')) {
        wsUrl = wsUrl.substring(0, wsUrl.length - 1);
      }
      
      final uri = Uri.parse('$wsUrl/ws?token=$token');
      print('🔌 Connecting to WebSocket: $uri');
      
      _channel = IOWebSocketChannel.connect(
        uri,
        pingInterval: const Duration(seconds: 30),
      );
      
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );
      
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      
      print('✅ WebSocket connected successfully');
      _controller.add(WebSocketEvent(WebSocketEventType.connected, null));
      
      _startPingTimer();
      
    } catch (e) {
      print('❌ Failed to connect WebSocket: $e');
      _isConnecting = false;
      _isConnected = false;
      _controller.add(WebSocketEvent(WebSocketEventType.error, e.toString()));
      _scheduleReconnect();
    }
  }
  
  void _handleMessage(dynamic message) {
    print('📨 WebSocket message: ${message.toString().length} chars');
    _controller.add(WebSocketEvent(WebSocketEventType.message, message));
  }
  
  void _handleError(dynamic error) {
    print('❌ WebSocket error: $error');
    _isConnected = false;
    _controller.add(WebSocketEvent(WebSocketEventType.error, error));
    _controller.add(WebSocketEvent(WebSocketEventType.disconnected, null));
    _scheduleReconnect();
  }
  
  void _handleDone() {
    print('🔌 WebSocket connection closed');
    _isConnected = false;
    _controller.add(WebSocketEvent(WebSocketEventType.disconnected, null));
    _scheduleReconnect();
  }
  
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected && _channel != null) {
        try {
          _channel!.sink.add(jsonEncode({
            'type': 'ping',
            'timestamp': DateTime.now().toIso8601String(),
          }));
          print('🏓 Sent ping');
        } catch (e) {
          print('❌ Error sending ping: $e');
        }
      }
    });
  }
  
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('⏹️ Max reconnect attempts reached');
      return;
    }
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(seconds: _reconnectAttempts * 2 + 1),
      () {
        _reconnectAttempts++;
        print('🔄 Attempting to reconnect WebSocket (attempt $_reconnectAttempts)');
        connect();
      },
    );
  }
  
  Future<void> _disconnect() async {
    try {
      _reconnectTimer?.cancel();
      _pingTimer?.cancel();
      await _subscription?.cancel();
      await _channel?.sink.close();
    } catch (e) {
      print('⚠️  Error disconnecting WebSocket: $e');
    } finally {
      _channel = null;
      _subscription = null;
      _reconnectTimer = null;
      _pingTimer = null;
      _isConnected = false;
      _isConnecting = false;
      print('🔌 WebSocket disconnected');
    }
  }
  
  void addListener(Function(WebSocketEvent) listener) {
    events.listen(listener);
  }
  
  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      try {
        final jsonString = jsonEncode(message);
        _channel!.sink.add(jsonString);
        print('📤 Sent message: ${message['type']}');
      } catch (e) {
        print('❌ Error sending message: $e');
      }
    } else {
      print('⚠️  Cannot send message: WebSocket not connected');
    }
  }
  
  void dispose() {
    _disconnect();
    _controller.close();
    print('♻️  WebSocketManager disposed');
  }
}