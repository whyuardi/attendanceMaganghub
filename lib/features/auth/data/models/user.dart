class User {
  final int id;
  final String name;
  final String email;
  final String employeeCode;
  final String role;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.employeeCode,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Supports flat structure or nested employee/user object from API
    final rawEmployee = json['employee'];
    final employeeData = rawEmployee is Map ? Map<String, dynamic>.from(rawEmployee) : null;

    return User(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? employeeData?['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      employeeCode: json['employee_code'] as String? ?? employeeData?['employee_code'] as String? ?? '',
      role: json['role'] as String? ?? 'employee',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'employee_code': employeeCode,
      'role': role,
    };
  }

  String get initials {
    if (name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }
}
