final class StatsTacticalOverview {
  final StatsTOEntry hosts;
  final StatsTOEntry services;

  const StatsTacticalOverview({
    required this.hosts,
    required this.services,
  });

  factory StatsTacticalOverview.fromJson(Map<String, dynamic> json) {
    return StatsTacticalOverview(
      hosts: StatsTOEntry.fromJson(json['hosts'] as Map<String, dynamic>),
      services: StatsTOEntry.fromJson(json['services'] as Map<String, dynamic>),
    );
  }

  StatsTacticalOverview copyWith({
    StatsTOEntry? hosts,
    StatsTOEntry? services,
  }) {
    return StatsTacticalOverview(
      hosts: hosts ?? this.hosts,
      services: services ?? this.services,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatsTacticalOverview &&
          hosts == other.hosts &&
          services == other.services;

  @override
  int get hashCode => hosts.hashCode ^ services.hashCode;

  @override
  String toString() {
    return 'StatsTacticalOverview(hosts: $hosts, services: $services)';
  }
}

final class StatsTOEntry {
  final int all;
  final int warn;
  final int crit;
  final int unkn;

  const StatsTOEntry({
    required this.all,
    required this.warn,
    required this.crit,
    required this.unkn,
  });

  factory StatsTOEntry.fromJson(Map<String, dynamic> json) {
    return StatsTOEntry(
      all: json['all'] as int,
      warn: json['warn'] as int,
      crit: json['crit'] as int,
      unkn: json['unkn'] as int,
    );
  }

  StatsTOEntry copyWith({
    int? all,
    int? warn,
    int? crit,
    int? unkn,
  }) {
    return StatsTOEntry(
      all: all ?? this.all,
      warn: warn ?? this.warn,
      crit: crit ?? this.crit,
      unkn: unkn ?? this.unkn,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatsTOEntry &&
          all == other.all &&
          warn == other.warn &&
          crit == other.crit &&
          unkn == other.unkn;

  @override
  int get hashCode =>
      all.hashCode ^ warn.hashCode ^ crit.hashCode ^ unkn.hashCode;

  @override
  String toString() {
    return 'StatsTOEntry(all: $all, warn: $warn, crit: $crit, unkn: $unkn)';
  }
}
