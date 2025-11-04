// models/system_model.dart
class SystemModel {
  final String deskripsi;
  final String deskripsi2;
  final String info;
  final String link;
  final String link2;
  final String version;
  final String version2;

  SystemModel({
    required this.deskripsi,
    required this.deskripsi2,
    required this.info,
    required this.link,
    required this.link2,
    required this.version,
    required this.version2,
  });

  // Factory constructor untuk create object dari Map (JSON)
  factory SystemModel.fromJson(Map<String, dynamic> json) {
    return SystemModel(
      deskripsi: json['deskripsi'] ?? '',
      deskripsi2: json['deskripsi2'] ?? '',
      info: json['info'] ?? '',
      link: json['link'] ?? '',
      link2: json['link2'] ?? '',
      version: json['version'] ?? '',
      version2: json['version2'] ?? '',
    );
  }

  // Convert object ke Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'deskripsi': deskripsi,
      'deskripsi2': deskripsi2,
      'info': info,
      'link': link,
      'link2': link2,
      'version': version,
      'version2': version2,
    };
  }

  // Copy with method untuk update data
  SystemModel copyWith({
    String? deskripsi,
    String? deskripsi2,
    String? info,
    String? link,
    String? link2,
    String? version,
    String? version2,
  }) {
    return SystemModel(
      deskripsi: deskripsi ?? this.deskripsi,
      deskripsi2: deskripsi2 ?? this.deskripsi2,
      info: info ?? this.info,
      link: link ?? this.link,
      link2: link2 ?? this.link2,
      version: version ?? this.version,
      version2: version2 ?? this.version2,
    );
  }

  @override
  String toString() {
    return 'SystemModel(\n'
        '  deskripsi: $deskripsi,\n'
        '  deskripsi2: $deskripsi2,\n'
        '  info: $info,\n'
        '  link: $link,\n'
        '  link2: $link2,\n'
        '  version: $version,\n'
        '  version2: $version2\n'
        ')';
  }

  // Method untuk compare dua object
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SystemModel &&
        other.deskripsi == deskripsi &&
        other.deskripsi2 == deskripsi2 &&
        other.info == info &&
        other.link == link &&
        other.link2 == link2 &&
        other.version == version &&
        other.version2 == version2;
  }

  @override
  int get hashCode {
    return deskripsi.hashCode ^
        deskripsi2.hashCode ^
        info.hashCode ^
        link.hashCode ^
        link2.hashCode ^
        version.hashCode ^
        version2.hashCode;
  }
}