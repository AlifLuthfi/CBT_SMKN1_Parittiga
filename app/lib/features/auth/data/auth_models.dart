class UserModel {
  final int     id;
  final String  name;
  final String  email;
  final String  role;
  final String? nip;
  final String? nis;
  final String? avatar;
  final String? className;

  const UserModel({required this.id, required this.name, required this.email, required this.role, this.nip, this.nis, this.avatar, this.className});

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id:     j['id']     as int,
    name:   j['name']   as String,
    email:  j['email']  as String,
    role:   j['role']   as String,
    nip:    j['nip']    as String?,
    nis:    j['nis']    as String?,
    avatar: j['avatar'] as String?,
    className: _extractClassName(j['enrolled_classes']),
  );

  static String? _extractClassName(dynamic classes) {
    if (classes is! List) return null;
    for (final e in classes) {
      try {
        final m = Map<String, dynamic>.from(e);
        if (m['name'] is String) return m['name'] as String;
      } catch (_) {}
    }
    return null;
  }

  Map<String, dynamic> toJson() => {'id':id,'name':name,'email':email,'role':role,'nip':nip,'nis':nis,'avatar':avatar};

  bool get isGuru  => role == 'guru';
  bool get isSiswa => role == 'siswa';
  bool get isAdmin => role == 'admin';

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}
