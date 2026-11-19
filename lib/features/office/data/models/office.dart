class Office {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final bool isActive;

  const Office({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 15,
    this.isActive = true,
  });

  factory Office.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Office(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: parseDouble(json['latitude'] ?? json['lat']),
      longitude: parseDouble(json['longitude'] ?? json['lng']),
      radiusMeters: json['radius_m'] is num
          ? (json['radius_m'] as num).toInt()
          : json['radiusMeters'] is num
          ? (json['radiusMeters'] as num).toInt()
          : int.tryParse(
                  json['radius_m']?.toString() ??
                      json['radiusMeters']?.toString() ??
                      '15',
                ) ??
                15,
      isActive: json['is_active'] is bool
          ? json['is_active'] as bool
          : json['isActive'] is bool
          ? json['isActive'] as bool
          : json['is_active']?.toString() == '1' ||
                json['is_active']?.toString().toLowerCase() == 'true' ||
                json['is_active']?.toString().toLowerCase() == 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'radius_m': radiusMeters,
      'is_active': isActive,
    };
  }

  String get formattedCoordinates => '$latitude, $longitude';
}
