import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_widgets.dart';

class UserModel {
  final int id; final String name, email, role, status; final String? nip, nis;
  const UserModel({required this.id, required this.name, required this.email, required this.role, required this.status, this.nip, this.nis});
  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id:     j['id']     as int,
    name:   j['name']   as String,
    email:  j['email']  as String,
    role:   j['role']   as String,
    status: j['status'] as String? ?? 'active',
    nip:    j['nip']    as String?,
    nis:    j['nis']    as String?,
  );
  bool get isActive => status == 'active';
  String get initials => name.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
}

final _usersProvider = FutureProvider.autoDispose.family<List<UserModel>, String?>((ref, role) async {
  try {
    final data = await ApiClient.get('/admin/users', params: {'role': role, 'per_page': 50});
    final list = (data['data'] as List?) ?? [];
    return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return _demoUsers;
  }
});

const _demoUsers = [
  UserModel(id:1, name:'Administrator',  email:'admin@examcore.id',       role:'admin', status:'active', nip:'000001'),
  UserModel(id:2, name:'Budi Santoso',   email:'guru@examcore.id',        role:'guru',  status:'active', nip:'198501012010011001'),
  UserModel(id:3, name:'Siti Rahayu',    email:'siti@examcore.id',        role:'guru',  status:'active', nip:'198702052012012002'),
  UserModel(id:4, name:'Ahmad Naufal',   email:'ahmadnaufal@siswa.id',    role:'siswa', status:'active', nis:'2024001'),
  UserModel(id:5, name:'Dita Kusuma',    email:'ditakusuma@siswa.id',     role:'siswa', status:'active', nis:'2024003'),
  UserModel(id:6, name:'Rizal Pratama',  email:'rizalpratama@siswa.id',   role:'siswa', status:'inactive',nis:'2024004'),
];

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});
  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  String? _roleFilter;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(_usersProvider(_roleFilter));
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Manajemen User'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(_usersProvider(_roleFilter))),
        ],
      ),
      body: Column(children: [
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(14,10,14,10),
          child: Column(children: [
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari nama atau email...',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () { _searchCtrl.clear(); setState(() {}); })
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _chip(null,    'Semua'),
                _chip('admin', 'Admin'),
                _chip('guru',  'Guru'),
                _chip('siswa', 'Siswa'),
              ]),
            ),
          ]),
        ),
        Expanded(child: users.when(
          loading: () => ListView(children: const [SkeletonListTile(), SkeletonListTile(), SkeletonListTile()]),
          error:   (e,_) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(_usersProvider(_roleFilter))),
          data:    (list) {
            final q = _searchCtrl.text.toLowerCase();
            final filtered = q.isEmpty ? list : list.where((u) => u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q)).toList();
            if (filtered.isEmpty) return const EmptyState(title: 'User tidak ditemukan', icon: Icons.person_off_outlined);
            return ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) => _userTile(filtered[i]),
            );
          },
        )),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateUserSheet(context),
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: Text('Tambah User', style: AppTextStyles.button),
      ),
    );
  }

  Widget _chip(String? val, String label) {
    final active = _roleFilter == val;
    return GestureDetector(
      onTap: () { setState(() => _roleFilter = val); ref.invalidate(_usersProvider(val)); },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.navy : AppColors.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.navy : AppColors.border),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: active ? Colors.white : AppColors.ink3)),
      ),
    );
  }

  Widget _userTile(UserModel u) {
    final roleColors = {'admin': AppColors.red, 'guru': AppColors.navy, 'siswa': AppColors.green};
    final roleColor  = roleColors[u.role] ?? AppColors.ink3;

    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: u.isActive ? roleColor.withOpacity(.15) : AppColors.bg,
          child: Text(u.initials, style: TextStyle(color: u.isActive ? roleColor : AppColors.ink3, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
        title: Row(children: [
          Expanded(child: Text(u.name, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: FontWeight.w500, fontSize: 13.5), overflow: TextOverflow.ellipsis)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: roleColor.withOpacity(.1), borderRadius: BorderRadius.circular(10)),
            child: Text(u.role, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: roleColor))),
        ]),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(children: [
            Expanded(child: Text(u.email, style: AppTextStyles.bodySmall.copyWith(fontSize: 11.5), overflow: TextOverflow.ellipsis)),
            if (!u.isActive) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(8)),
              child: const Text('Non-aktif', style: TextStyle(fontSize: 9.5, color: AppColors.red, fontWeight: FontWeight.w600))),
          ]),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 18, color: AppColors.ink3),
          itemBuilder: (_) => [
            if (u.role == 'siswa')
              PopupMenuItem(value: 'class', child: const Row(children: [Icon(Icons.class_outlined, size: 16, color: AppColors.navy), SizedBox(width: 8), Text('Pindah Kelas')]), onTap: () => _updateKelas(u)),
            PopupMenuItem(value: 'reset',  child: const Text('Reset Password'), onTap: () => _resetPassword(u)),
            PopupMenuItem(value: 'toggle', child: Text(u.isActive ? 'Nonaktifkan' : 'Aktifkan'), onTap: () => _toggleStatus(u)),
            PopupMenuItem(value: 'delete', child: const Text('Hapus', style: TextStyle(color: AppColors.red)), onTap: () => _deleteUser(u)),
          ],
        ),
      ),
    );
  }

  void _resetPassword(UserModel u) {
    final passCtrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('Reset Password\n${u.name}'),
      content: TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password Baru', hintText: 'Minimal 8 karakter')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () async {
            if (passCtrl.text.length < 8) return;
            try { await ApiClient.patch('/admin/users/${u.id}/reset-password', data: {'password': passCtrl.text}); }
            catch (_) {}
            if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password ${u.name} direset'))); }
          },
          style: ElevatedButton.styleFrom(minimumSize: const Size(0,0), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
          child: const Text('Reset'),
        ),
      ],
    ));
  }

  Future<void> _toggleStatus(UserModel u) async {
    try { await ApiClient.patch('/admin/users/${u.id}/toggle-status'); }
    catch (_) {}
    ref.invalidate(_usersProvider(_roleFilter));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status ${u.name} diubah')));
  }

  Future<void> _deleteUser(UserModel u) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Hapus User?'),
      content: Text('Hapus akun "${u.name}"? Tindakan tidak dapat dibatalkan.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, minimumSize: const Size(0,0), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
          child: const Text('Hapus'),
        ),
      ],
    ));
    if (ok != true) return;
    try { await ApiClient.delete('/admin/users/${u.id}'); }
    catch (_) {}
    ref.invalidate(_usersProvider(_roleFilter));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${u.name} dihapus')));
  }

  void _updateKelas(UserModel u) {
    int? classId;
    final classesFuture = ApiClient.get('/admin/classes');
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx2, setS) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            Text('Pindah Kelas — ${u.name}', style: AppTextStyles.h4),
            const SizedBox(height: 14),
            FutureBuilder<dynamic>(
              future: classesFuture,
              builder: (_, snap) {
                if (snap.connectionState != ConnectionState.done) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
                if (snap.hasError) return Text('Gagal memuat kelas: ${snap.error}', style: const TextStyle(color: AppColors.red, fontSize: 12));
                final classes = ((snap.data as Map<String, dynamic>)['data'] as List? ?? []);
                return DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Pilih Kelas', prefixIcon: Icon(Icons.class_outlined, size: 18)),
                  items: classes.map((c) => DropdownMenuItem<int>(value: c['id'] as int, child: Text('${c['name']} · ${c['subject']}'))).toList(),
                  onChanged: (v) => setS(() => classId = v),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (classId == null) { ScaffoldMessenger.of(ctx2).showSnackBar(const SnackBar(content: Text('Pilih kelas terlebih dahulu'))); return; }
                try {
                  await ApiClient.put('/admin/users/${u.id}/class', data: {'class_id': classId});
                  ref.invalidate(_usersProvider(_roleFilter));
                  if (ctx2.mounted) { Navigator.pop(ctx2); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kelas siswa berhasil diperbarui'))); }
                } catch (e) {
                  if (ctx2.mounted) ScaffoldMessenger.of(ctx2).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text('Simpan'),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      )),
    );
  }

  void _showCreateUserSheet(BuildContext ctx) {
    final nameCtrl   = TextEditingController();
    final emailCtrl  = TextEditingController();
    final passCtrl   = TextEditingController();
    final nipNisCtrl = TextEditingController();
    String role = 'siswa';
    int? classId;
    final classesFuture = ApiClient.get('/admin/classes');
    showModalBottomSheet(
      context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx2, setS) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          height: MediaQuery.of(ctx).size.height * .8,
          decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          child: Column(children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            Padding(padding: const EdgeInsets.fromLTRB(18,0,18,12), child: Row(children: [
              Text('Tambah User Baru', style: AppTextStyles.h4), const Spacer(),
              TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('Batal')),
            ])),
            const Divider(height: 1),
            Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(18), child: Column(children: [
              // Role selector
              Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(9)),
                child: Row(children: ['guru','siswa'].map((r) {
                  final active = role == r;
                  return Expanded(child: GestureDetector(
                    onTap: () => setS(() => role = r),
                    child: Container(padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: active ? AppColors.surface : Colors.transparent, borderRadius: BorderRadius.circular(6), boxShadow: active ? [const BoxShadow(color: Colors.black12, blurRadius: 3)] : null),
                      child: Text(r.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? AppColors.navy : AppColors.ink3))),
                  ));
                }).toList()),
              ),
              const SizedBox(height: 14),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap *', prefixIcon: Icon(Icons.person_outline, size: 18))),
              const SizedBox(height: 10),
              TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email *', prefixIcon: Icon(Icons.email_outlined, size: 18))),
              const SizedBox(height: 10),
              TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password *', prefixIcon: Icon(Icons.lock_outline, size: 18))),
              const SizedBox(height: 10),
              TextField(controller: nipNisCtrl, decoration: InputDecoration(labelText: role == 'siswa' ? 'NIS' : 'NIP', prefixIcon: const Icon(Icons.badge_outlined, size: 18))),
              if (role == 'siswa') ...[
                const SizedBox(height: 10),
                FutureBuilder<dynamic>(
                  future: classesFuture,
                  builder: (_, snap) {
                    if (snap.connectionState != ConnectionState.done) return const LinearProgressIndicator(minHeight: 2);
                    if (snap.hasError) return Text('Gagal memuat kelas: ${snap.error}', style: const TextStyle(color: AppColors.red, fontSize: 12));
                    final classes = ((snap.data as Map<String, dynamic>)['data'] as List? ?? []);
                    return DropdownButtonFormField<int>(
                      initialValue: classId,
                      decoration: const InputDecoration(labelText: 'Kelas Siswa *', prefixIcon: Icon(Icons.class_outlined, size: 18)),
                      items: classes.map((c) => DropdownMenuItem<int>(value: c['id'] as int, child: Text('${c['name']} · ${c['subject']}'))).toList(),
                      onChanged: (v) => setS(() => classId = v),
                    );
                  },
                ),
              ],
            ]))),
            Container(
              padding: const EdgeInsets.fromLTRB(18,12,18,24),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
              child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty || passCtrl.text.isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Nama, email, dan password wajib diisi'))); return; }
                  if (role == 'siswa' && classId == null) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Kelas siswa wajib dipilih'))); return; }
                  try {
                    final data = await ApiClient.post('/admin/users', data: {
                      'name': nameCtrl.text, 'email': emailCtrl.text, 'password': passCtrl.text, 'role': role,
                      if (role == 'siswa') 'nis': nipNisCtrl.text,
                      if (role != 'siswa') 'nip': nipNisCtrl.text,
                    }) as Map<String, dynamic>;
                    if (role == 'siswa' && classId != null) {
                      final user = data['user'] as Map<String, dynamic>;
                      await ApiClient.post('/guru/classes/$classId/students', data: {'student_ids': [user['id']]});
                    }
                    ref.invalidate(_usersProvider(_roleFilter));
                    if (ctx2.mounted) { Navigator.pop(ctx2); ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('User berhasil dibuat'))); }
                  } catch (e) {
                    if (ctx2.mounted) ScaffoldMessenger.of(ctx2).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                child: const Text('Buat User'),
              ),
            ),
          ]),
        ),
      )),
    );
  }
}
