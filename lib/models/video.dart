class Video {
  final String camera;
  final String type;
  final int importanceLevel;
  final DateTime recordedAt;
  final Duration recordLength;
  final String hash;

  Video({required this.hash, required this.camera, required this.type, required this.importanceLevel, required this.recordedAt, required this.recordLength});

  factory Video.fromJson(Map<String, dynamic> json) {
    final recordLengthRaw = json['record_length'];
    final recordLengthSeconds = recordLengthRaw is String
        ? double.parse(recordLengthRaw).round()
        : (recordLengthRaw as num).round();

    return Video(
      hash: json['hash'],
      camera: json['camera'],
      type: json['type'],
      importanceLevel: json['importance_level'],
      recordedAt: DateTime.parse(json['recorded_at']),
      recordLength: Duration(seconds: recordLengthSeconds),
      // recordLength: Duration(
      //   seconds: _parseDuration(json['record_length']),
      // ),
    );
  }

  // static int _parseDuration(String time) {
  //   final parts = time.split(':').map(int.parse).toList();
  //   return parts[0] * 3600 + parts[1] * 60 + parts[2];
  // }
}
