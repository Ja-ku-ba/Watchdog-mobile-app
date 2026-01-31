class Video {
  final String url;
  final String? hash;
  final String? camera;
  final String? type;
  final int? importanceLevel;
  final DateTime? recordedAt;

  Video({
    required this.url,
    this.hash,
    this.camera,
    this.type,
    this.importanceLevel,
    this.recordedAt,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      url: json['url'],
      hash: json['hash'],
      camera: json['camera'],
      type: json['type'],
      importanceLevel: json['importance_level'],
      recordedAt: json['recorded_at'] != null
          ? DateTime.tryParse(json['recorded_at'])
          : null,
    );
  }
}
