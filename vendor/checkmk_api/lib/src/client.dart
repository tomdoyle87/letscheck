import 'dart:async';
import 'dart:io' if (kIsWeb) 'dart:html';

import 'package:rxdart/rxdart.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:dio/dio.dart';

import 'consts.dart';
import 'exceptions.dart';
import './models/models.dart';

class ClientSettings {
  final String baseUrl;
  final String site;
  final bool insecure;

  final String username;
  final String secret;

  ClientSettings(
      {required this.baseUrl,
      required this.site,
      required this.username,
      required this.secret,
      this.insecure = false});
}

/// Represents the current state of the connection to the Check_MK server
enum ConnectionState {
  /// Initial state, nothing happened/happens
  initial,

  /// Disconnected from the server, this is also the initial state.
  disconnected,

  /// Currently attempting to connect
  connecting,

  /// Successfully connected to the server
  connected,

  /// Connection failed or error happened
  error,

  /// Connection is paused, e.g. by a user action
  paused,
}

class NoCertHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
  }
}

class Client {
  final Dio Function() dioFactory;
  final ClientSettings settings;
  final Duration keepAliveInterval;

  late Dio dio;

  // Connection state handling
  late final BehaviorSubject<ConnectionState> _connectionStateController;
  ConnectionState _currentState = ConnectionState.initial;

  /// Stream of connection state changes
  Stream<ConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// Current connection state
  ConnectionState get connectionState => _currentState;

  ConnectionState _requestedState = ConnectionState.connected;
  ConnectionState get requestedConnectionState => _requestedState;

  BaseException? _lastError;
  Timer? _keepAliveTimer;

  Client(this.dioFactory, this.settings,
      {this.keepAliveInterval = const Duration(seconds: 60),
      bool requireConnect = true}) {
    _connectionStateController =
        BehaviorSubject<ConnectionState>.seeded(_currentState);

    if (!requireConnect) _currentState = ConnectionState.connected;

    dio = dioFactory();

    dio.options.baseUrl = settings.baseUrl;
    dio.options.contentType = Headers.formUrlEncodedContentType;

    if (!kIsWeb && settings.insecure) {
      HttpOverrides.global = NoCertHttpOverrides();
    }
  }

  void _updateConnectionState(ConnectionState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _connectionStateController.add(newState);
    }
  }

  void _checkConnection() {
    if (_currentState != ConnectionState.connected) {
      throw _lastError ?? NotConnectedException();
    }
  }

  void _keepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(keepAliveInterval, (timer) async {
      if (_requestedState != ConnectionState.connected) return;

      try {
        testConnection(setError: false);
        _updateConnectionState(ConnectionState.connected);
      } catch (_) {
        _updateConnectionState(ConnectionState.error);
      }
    });
  }

  BaseException error() {
    return _lastError ?? NotConnectedException();
  }

  /// Dispose of the client and clean up resources
  void dispose() {
    _keepAliveTimer?.cancel();
    _connectionStateController.close();
  }

  Future<void> testConnection({bool setError = true}) async {
    try {
      await dio.request("/${settings.site}/check_mk/login.py");
    } on DioException catch (e) {
      if (setError) {
        _lastError = NetworkException.of(e);
        throw _lastError!;
      } else {
        throw NetworkException.of(e);
      }
    } on Exception catch (e) {
      if (setError) {
        _lastError = NetworkException.of(e);
        throw _lastError!;
      } else {
        throw NetworkException.of(e);
      }
    }
  }

  Future<void> connect() async {
    _requestedState = ConnectionState.connected;
    try {
      _updateConnectionState(ConnectionState.connecting);
      await testConnection();
      _updateConnectionState(ConnectionState.connected);
    } catch (_) {
      // Ignore.
    } finally {
      _keepAlive();
    }
  }

  void disconnect({BaseException? reason}) {
    _requestedState = ConnectionState.disconnected;
    _keepAliveTimer?.cancel();
    _updateConnectionState(ConnectionState.disconnected);

    if (reason != null) {
      _lastError = reason;
    } else {
      _lastError ??= NotConnectedException();
    }
  }

  void pause({String reason = 'Paused'}) {
    _keepAliveTimer?.cancel();

    _lastError = BaseException(message: reason);

    _requestedState = ConnectionState.paused;
    _updateConnectionState(ConnectionState.paused);
  }

  Future<Response> requestApi(
      {String method = 'GET',
      String url = '',
      Map<String, dynamic> query = const {},
      dynamic data}) async {
    Uri uri = Uri(
        path: "/${settings.site}/check_mk/api/1.0$url", queryParameters: query);

    _checkConnection();

    var auth = 'Bearer ${settings.username} ${settings.secret}';

    Map<String, dynamic> requestData = {};
    if (data != null) {
      requestData["request"] = data;
    }

    try {
      final response = await dio.request(uri.toString(),
          options: Options(
            method: method,
            headers: <String, String>{
              'authorization': auth,
              'content-type': 'application/json',
              'accept': 'application/json',
            },
          ),
          data: data);
      return response;
    } on DioException catch (e) {
      _lastError = NetworkException.of(e);
      throw _lastError!;
    } on Exception catch (e) {
      _lastError = NetworkException.of(e);
      throw _lastError!;
    }
  }

  Future<Response> requestApiCollection(String table,
      {List<String>? columns, List<String>? filter}) async {
    Map<String, dynamic> query = {};

    if (columns != null) {
      query["columns"] = columns;
    }
    if (filter != null) {
      query["query"] = filter;
    }
    if (query.isNotEmpty) {
      return await requestApi(
          method: 'GET',
          url: '/domain-types/$table/collections/all',
          query: query);
    }

    return await requestApi(
        method: 'GET', url: '/domain-types/$table/collections/all');
  }

  Future<List<Host>> getApiHosts(
      {List<String>? columns, List<String>? filter}) async {
    columns ??= columns = [
      'state',
      'acknowledged',
      'name',
      'alias',
      'address',
      'display_name',
      'groups',
      'labels',
      'parents',
      'tags',
      'latency',
    ];

    var response =
        await requestApiCollection('host', columns: columns, filter: filter);

    List<Host> result = [];
    response.data["value"].forEach((item) {
      result.add(Host.fromJson(item['extensions']));
    });
    return List.from(result, growable: false);
  }

  Future<List<Service>> getApiServices(
      {List<String>? columns, List<String>? filter}) async {
    columns ??= columns = [
      'state',
      'acknowledged',
      'host_name',
      'display_name',
      'description',
      'plugin_output',
      'comments',
      'last_state_change',
    ];

    var response =
        await requestApiCollection('service', columns: columns, filter: filter);

    List<Service> result = [];
    response.data["value"].forEach((item) {
      result.add(Service.fromJson(item['extensions']));
    });
    return List.from(result, growable: false);
  }

  Future<List<Comment>> getApiComments(
      {List<String>? columns, List<String>? filter}) async {
    var response =
        await requestApiCollection('comment', columns: columns, filter: filter);

    List<Comment> result = [];
    response.data["value"].forEach((item) {
      result.add(Comment.fromJson(item['extensions']));
    });
    return List.from(result, growable: false);
  }

  Future<StatsTacticalOverview> getApiStatsTacticalOverview() async {
    final hosts = await getApiHosts(columns: ['state']);
    int hAll = 0, hDown = 0, hUnreachable = 0;
    for (var h in hosts) {
      hAll += 1;
      switch (h.state) {
        case hostStateDown:
          hDown += 1;
          break;
        case hostStateUnreachable:
          hUnreachable += 1;
          break;
      }
    }

    final services = await getApiServices(columns: ['state']);
    int sAll = 0, sWarn = 0, sCrit = 0, sUnkn = 0;

    for (var s in services) {
      sAll += 1;
      switch (s.state) {
        case svcStateWarn:
          sWarn += 1;
          break;
        case svcStateCritical:
          sCrit += 1;
          break;
        case svcStateUnknown:
          sUnkn += 1;
          break;
      }
    }

    return StatsTacticalOverview(
      hosts: StatsTOEntry(
        all: hAll,
        warn: hDown,
        crit: hUnreachable,
        unkn: 0,
      ),
      services: StatsTOEntry(
        all: sAll,
        warn: sWarn,
        crit: sCrit,
        unkn: sUnkn,
      ),
    );
  }

  Future<Response> requestView(String view,
      {Map<String, dynamic> query = const {}}) async {
    _checkConnection();

    query['view_name'] = view;
    query['output_format'] = 'json';

    Uri uri =
        Uri(path: "/${settings.site}/check_mk/view.py", queryParameters: query);

    try {
      final response = await dio.request(
        uri.toString(),
        options: Options(
          method: 'GET',
          headers: <String, String>{
            'authorization': 'Bearer ${settings.username} ${settings.secret}',
            'content-type': 'application/json',
            'accept': 'application/json',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      _lastError = NetworkException.of(e);
      throw _lastError!;
    } on Exception catch (e) {
      _lastError = NetworkException.of(e);
      throw _lastError!;
    }
  }

  Future<List<Log>> getViewEvents({int fromSecs = 60}) async {
    final query = <String, dynamic>{
      'logtime_from': fromSecs.toString(),
      'logtime_from_range': '1',
      'logst_h1': 'on',
      'logst_h2': 'on',
      'logst_s1': 'on',
      'logst_s2': 'on',
      'logst_s3': 'on',
    };

    var response = await requestView('events', query: query);

    if (response.data.length < 2) {
      return [];
    }

    var result = <Log>[];
    final headers = response.data[0];
    for (var ir = 1; ir < response.data.length; ir++) {
      var row = response.data[ir];
      int? state;
      DateTime? time;
      String? hostName;
      String? displayName;
      String? pluginOutput;

      for (var ih = 0; ih < headers.length; ih++) {
        switch (headers[ih]) {
          case 'log_icon':
            if (row[ih] != 'Service alert' && row[ih] != 'Host alert') {
              break;
            }
            break;
          case 'log_time':
            final now = DateTime.now();
            final s = row[ih].toString();
            if (s.endsWith('s')) {
              time = now
                  .subtract(Duration(seconds: int.parse(s.split('.')[0])))
                  .toUtc();
            } else if (s.endsWith('m')) {
              time = now
                  .subtract(Duration(minutes: int.parse(s.split(' ')[0])))
                  .toUtc();
            } else if (s.endsWith('h')) {
              time = now
                  .subtract(Duration(hours: int.parse(s.split(' ')[0])))
                  .toUtc();
            }
            break;
          case 'log_type':
            break;
          case 'host':
            hostName = row[ih].toString();
            break;
          case 'service_description':
            displayName = row[ih].toString();
            break;
          case 'log_state_info':
            final s = row[ih].toString();
            if (s.contains('DOWN')) {
              state = svcStateUnknown;
            } else if (s.contains('CRITICAL')) {
              state = svcStateCritical;
            } else if (s.contains('WARNING')) {
              state = svcStateWarn;
            }
            break;
          case 'log_plugin_output':
            pluginOutput = row[ih].toString();
            break;
          default:
        }
      }

      // Nothing found.
      if (state == null) {
        continue;
      }

      result.add(
        Log(
          state: state,
          time: time!,
          hostName: hostName!,
          displayName: displayName!,
          pluginOutput: pluginOutput!,
        ),
      );
    }

    return List.from(result, growable: false);
  }

  @override
  String toString() {
    return 'checkmk_api.Client: ${settings.baseUrl}';
  }
}
