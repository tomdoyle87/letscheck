final class Comment {
  final int id;
  final String? author;
  final String? comment;
  final String? hostName;
  final String? entryTime;
  final int? entryType;
  final bool? persistent;
  final bool? isService;
  final String? serviceDescription;

  const Comment({
    required this.id,
    this.author,
    this.comment,
    this.hostName,
    this.entryTime,
    this.entryType,
    this.persistent,
    this.isService,
    this.serviceDescription,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int,
      author: json['author'] as String?,
      comment: json['comment'] as String?,
      hostName: json['host_name'] as String?,
      entryTime: json['entry_time'] as String?,
      entryType: json['entry_type'] as int?,
      persistent: json['persistent'] as bool?,
      isService: json['is_service'] as bool?,
      serviceDescription: json['service_description'] as String?,
    );
  }

  Comment copyWith({
    int? id,
    String? author,
    String? comment,
    String? hostName,
    String? entryTime,
    int? entryType,
    bool? persistent,
    bool? isService,
    String? serviceDescription,
  }) {
    return Comment(
      id: id ?? this.id,
      author: author ?? this.author,
      comment: comment ?? this.comment,
      hostName: hostName ?? this.hostName,
      entryTime: entryTime ?? this.entryTime,
      entryType: entryType ?? this.entryType,
      persistent: persistent ?? this.persistent,
      isService: isService ?? this.isService,
      serviceDescription: serviceDescription ?? this.serviceDescription,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Comment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          author == other.author &&
          comment == other.comment &&
          hostName == other.hostName &&
          entryTime == other.entryTime &&
          entryType == other.entryType &&
          persistent == other.persistent &&
          isService == other.isService &&
          serviceDescription == other.serviceDescription;

  @override
  int get hashCode =>
      id.hashCode ^
      author.hashCode ^
      comment.hashCode ^
      hostName.hashCode ^
      entryTime.hashCode ^
      entryType.hashCode ^
      persistent.hashCode ^
      isService.hashCode ^
      serviceDescription.hashCode;

  @override
  String toString() {
    return 'Comment(id: $id, author: $author, comment: $comment, hostName: $hostName, entryTime: $entryTime, entryType: $entryType, persistent: $persistent, isService: $isService, serviceDescription: $serviceDescription)';
  }
}
