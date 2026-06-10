final class Service {
  final int state;
  final int? acknowledged;
  final String? hostName;
  final String? displayName;
  final String? description;
  final String? pluginOutput;
  final List<int>? comments;
  final DateTime? lastStateChange;

  const Service({
    required this.state,
    this.acknowledged,
    this.hostName,
    this.displayName,
    this.description,
    this.pluginOutput,
    this.comments,
    this.lastStateChange,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      state: json['state'] as int,
      acknowledged: json['acknowledged'] as int?,
      hostName: json['host_name'] as String?,
      displayName: json['display_name'] as String?,
      description: json['description'] as String?,
      pluginOutput: json['plugin_output'] as String?,
      comments: (json['comments'] as List<dynamic>?)?.cast<int>(),
      lastStateChange: json['last_state_change'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              ((json['last_state_change'] as int) * 1000).round())
          : null,
    );
  }

  Service copyWith({
    int? state,
    int? acknowledged,
    String? hostName,
    String? displayName,
    String? description,
    String? pluginOutput,
    List<int>? comments,
    DateTime? lastStateChange,
  }) {
    return Service(
      state: state ?? this.state,
      acknowledged: acknowledged ?? this.acknowledged,
      hostName: hostName ?? this.hostName,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      pluginOutput: pluginOutput ?? this.pluginOutput,
      comments: comments ?? this.comments,
      lastStateChange: lastStateChange ?? this.lastStateChange,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Service &&
          runtimeType == other.runtimeType &&
          state == other.state &&
          acknowledged == other.acknowledged &&
          hostName == other.hostName &&
          displayName == other.displayName &&
          description == other.description &&
          pluginOutput == other.pluginOutput &&
          comments == other.comments &&
          lastStateChange == other.lastStateChange;

  @override
  int get hashCode =>
      state.hashCode ^
      acknowledged.hashCode ^
      hostName.hashCode ^
      displayName.hashCode ^
      description.hashCode ^
      pluginOutput.hashCode ^
      comments.hashCode ^
      lastStateChange.hashCode;

  @override
  String toString() {
    return 'Service(state: $state, acknowledged: $acknowledged, hostName: $hostName, displayName: $displayName, description: $description, pluginOutput: $pluginOutput, comments: $comments, lastStateChange: $lastStateChange)';
  }
}
