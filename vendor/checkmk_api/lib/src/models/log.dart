final class Log {
  final int state;
  final String hostName;
  final String displayName;
  final String pluginOutput;
  final DateTime time;

  const Log({
    required this.state,
    required this.hostName,
    required this.displayName,
    required this.pluginOutput,
    required this.time,
  });

  factory Log.fromJson(Map<String, dynamic> json) {
    return Log(
      state: json['state'] as int,
      hostName: json['host_name'] as String,
      displayName: json['display_name'] as String,
      pluginOutput: json['plugin_output'] as String,
      time: DateTime.fromMillisecondsSinceEpoch(
          ((json['time'] as int) * 1000).round()),
    );
  }

  Log copyWith({
    int? state,
    String? hostName,
    String? displayName,
    String? pluginOutput,
    DateTime? time,
  }) {
    return Log(
      state: state ?? this.state,
      hostName: hostName ?? this.hostName,
      displayName: displayName ?? this.displayName,
      pluginOutput: pluginOutput ?? this.pluginOutput,
      time: time ?? this.time,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Log &&
          runtimeType == other.runtimeType &&
          state == other.state &&
          hostName == other.hostName &&
          displayName == other.displayName &&
          pluginOutput == other.pluginOutput &&
          time == other.time;

  @override
  int get hashCode =>
      state.hashCode ^
      hostName.hashCode ^
      displayName.hashCode ^
      pluginOutput.hashCode ^
      time.hashCode;

  @override
  String toString() {
    return 'Log(state: $state, hostName: $hostName, displayName: $displayName, pluginOutput: $pluginOutput, time: $time)';
  }
}
