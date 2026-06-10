class BaseException implements Exception {
  String message = 'Unknown error';

  BaseException({String? message}) {
    if (message != null) {
      this.message = message;
    }
  }

  @override
  String toString() {
    return message;
  }
}

class NotConnectedException extends BaseException {
  NotConnectedException()
      : super(message: 'Not connected to the Checkmk server');
}

class NetworkException extends BaseException {
  NetworkException({
    required super.message,
  });

  static NetworkException of<T extends Exception>(T e) {
    return NetworkException(message: e.toString());
  }

  @override
  String toString() {
    return 'NetworkException: $message';
  }
}
