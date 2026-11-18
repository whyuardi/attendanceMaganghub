class Office {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int radiusM;

  const Office({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.radiusM = 15,
  });

  factory Office.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Office(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: parseDouble(json['latitude'] ?? json['lat']),
      longitude: parseDouble(json['longitude'] ?? json['lng']),
      radiusM: json['radius_m'] is num
          ? (json['radius_m'] as num).toInt()
          : int.tryParse(json['radius_m']?.toString() ?? '15') ?? 15,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'radius_m': radiusM,
    };
  }

  String get formattedCoordinates => '$latitude, $longitude';
}
