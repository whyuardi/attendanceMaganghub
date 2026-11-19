class Office {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int radiusM;
  final bool isActive;

  static const defaultOffice = Office(
    id: 1,
    name: 'Ethes Tech (Kantor Pusat)',
    address: 'Krajan 1 Kandangan, 001/007, Krajan, Kandangan, Temanggung Regency, Central Java 56281',
    latitude: -7.2547327062062426,
    longitude: 110.1850411247732,
    radiusM: 15,
    isActive: true,
  );

  const Office({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    int? radiusMeters,
    int radiusM = 15,
    this.isActive = true,
  }) : radiusM = radiusMeters ?? radiusM;

  factory Office.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final rawIsActive = json['is_active'] ?? json['isActive'];
    final isActive = rawIsActive == null
        ? true
        : (rawIsActive == 1 || rawIsActive == true || rawIsActive == '1');

    return Office(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: parseDouble(json['latitude'] ?? json['lat']),
      longitude: parseDouble(json['longitude'] ?? json['lng']),
      radiusM: json['radius_m'] is num
          ? (json['radius_m'] as num).toInt()
          : (json['radiusMeters'] is num
              ? (json['radiusMeters'] as num).toInt()
              : int.tryParse(json['radius_m']?.toString() ?? json['radiusMeters']?.toString() ?? '15') ?? 15),
      isActive: isActive,
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
      'is_active': isActive ? 1 : 0,
    };
  }

  int get radiusMeters => radiusM;

  String get formattedCoordinates => '$latitude, $longitude';
}
