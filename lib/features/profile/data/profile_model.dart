class ProfileModel {
  final String id;
  final String name;
  final String avatarUrl;
  final String role;

  ProfileModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.role,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json, String publicUrl) {
    return ProfileModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      avatarUrl: publicUrl,
      role: json['role'] ?? '',
    );
  }
}
