class VerifiedUserModel {
  final String name;
  final String hash;
  final int filesCounter;
  final List<String>? imageHashes;

  VerifiedUserModel({
    required this.name,
    required this.hash,
    required this.filesCounter,
    this.imageHashes,
  });

  // deserialize
  factory VerifiedUserModel.fromJson(Map<String, dynamic> json) {
    return VerifiedUserModel(
      name: json['name'] ?? '',
      hash: json['hash'] ?? '',
      filesCounter: json['files_counter'] ?? 0,
      imageHashes: json['image_hashes'] != null
          ? List<String>.from(json['image_hashes'])
          : null,
    );
  }

  // serialize
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'hash': hash,
      'files_counter': filesCounter,
      'image_hashes': imageHashes,
    };
  }

  VerifiedUserModel copyWith({
    String? name,
    String? hash,
    int? filesCounter,
    List<String>? imageHashes,
  }) {
    return VerifiedUserModel(
      name: name ?? this.name,
      hash: hash ?? this.hash,
      filesCounter: filesCounter ?? this.filesCounter,
      imageHashes: imageHashes ?? this.imageHashes,
    );
  }
}
