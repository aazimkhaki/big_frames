class S3Connection {
  final String id;
  final String name;
  final String accessKey;
  final String secretKey;
  final String region;
  final String endpoint;

  const S3Connection({
    required this.id,
    required this.name,
    required this.accessKey,
    required this.secretKey,
    required this.region,
    required this.endpoint,
  });

  S3Connection copyWith({
    String? id,
    String? name,
    String? accessKey,
    String? secretKey,
    String? region,
    String? endpoint,
  }) {
    return S3Connection(
      id: id ?? this.id,
      name: name ?? this.name,
      accessKey: accessKey ?? this.accessKey,
      secretKey: secretKey ?? this.secretKey,
      region: region ?? this.region,
      endpoint: endpoint ?? this.endpoint,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'accessKey': accessKey,
      // intentionally exclude secretKey from standard json payload
      // secretKey should be handled via secure storage
      'region': region,
      'endpoint': endpoint,
    };
  }

  factory S3Connection.fromJson(Map<String, dynamic> json, {String? secretKey}) {
    return S3Connection(
      id: json['id'] as String,
      name: json['name'] as String,
      accessKey: json['accessKey'] as String,
      secretKey: secretKey ?? '',
      region: json['region'] as String,
      endpoint: json['endpoint'] as String,
    );
  }
}
