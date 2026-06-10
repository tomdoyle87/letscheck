final class Host {
  final int state;
  final int? acknowledged;
  final String? hostName;
  final String? displayName;
  final String? alias; // Added alias field
  final String? pluginOutput;
  final List<num>? comments;
  final DateTime? lastStateChange;

  const Host({
    required this.state,
    this.acknowledged,
    this.hostName,
    this.displayName,
    this.alias,
    this.pluginOutput,
    this.comments,
    this.lastStateChange,
  });

  factory Host.fromJson(Map<String, dynamic> json) {
    return Host(
      state: json['state'] as int,
      acknowledged: json['acknowledged'] as int?,
      hostName: json['name'] as String?,
      displayName: json['display_name'] as String?,
      alias: json['alias'] as String?, // Mapped from JSON
      pluginOutput: json['plugin_output'] as String?,
      comments: (json['comments'] as List<dynamic>?)?.cast<num>(),
      lastStateChange: json['last_state_change'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              ((json['last_state_change'] as int) * 1000).round())
          : null,
    );
  }

  Host copyWith({
    int? state,
    int? acknowledged,
    String? hostName,
    String? displayName,
    String? alias,
    String? pluginOutput,
    List<num>? comments,
    DateTime? lastStateChange,
  }) {
    return Host(
      state: state ?? this.state,
      acknowledged: acknowledged ?? this.acknowledged,
      hostName: hostName ?? this.hostName,
      displayName: displayName ?? this.displayName,
      alias: alias ?? this.alias,
      pluginOutput: pluginOutput ?? this.pluginOutput,
      comments: comments ?? this.comments,
      lastStateChange: lastStateChange ?? this.lastStateChange,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Host &&
          runtimeType == other.runtimeType &&
          state == other.state &&
          acknowledged == other.acknowledged &&
          hostName == other.hostName &&
          displayName == other.displayName &&
          alias == other.alias &&
          pluginOutput == other.pluginOutput &&
          comments == other.comments &&
          lastStateChange == other.lastStateChange;

  @override
  int get hashCode =>
      state.hashCode ^
      acknowledged.hashCode ^
      hostName.hashCode ^
      displayName.hashCode ^
      alias.hashCode ^
      pluginOutput.hashCode ^
      comments.hashCode ^
      lastStateChange.hashCode;

  @override
  String toString() {
    return 'Host(state: $state, acknowledged: $acknowledged, hostName: $hostName, displayName: $displayName, alias: $alias, pluginOutput: $pluginOutput, comments: $comments, lastStateChange: $lastStateChange)';
  }
}
