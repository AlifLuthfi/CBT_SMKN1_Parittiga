import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_widgets.dart';

// ── Model ──
class UserModel {
  final int id; final String name, email, role, status; final String? nip, nis;
  final List<Map<String, dynamic>> classRooms, enrolledClasses;
  const UserModel({required this.id, required this.name, required this.email, required this.role, required this.status, this.nip, this.nis, this.classRooms = const [], this.enrolledClasses = const []});
  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id'] as int, name: j['name'] as String, email: j['email'] as String,
    role: j['role'] as String, status: j['status'] as String? ?? 'active',
    nip: j['nip'] as String?, nis: j['nis'] as String?,
    classRooms: (j['class_rooms'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [],
    enrolledClasses: (j['enrolled_classes'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [],
  );
  bool get isActive => status == 'active';
  String get initials => name.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
  List<String> get classNames => (role == 'guru' ? classRooms : enrolledClasses).map((c) => '${c['name'] ?? ''} (${c['subject'] ?? ''})').toList();
  String? get levelLabel {
    final levels = (role == 'guru' ? classRooms : enrolledClasses).map((c) => c['level'] as String?).whereType<String>().toSet().toList();
    if (levels.isEmpty) return null;
    return 'Kelas ${levels.join(', ')}';
  }
}

class RoleConfig {
  final String key, label;
  final IconData icon;
  final Color color, colorLight;
  const RoleConfig(this.key, this.label, this.icon, this.color, this.colorLight);
}
const roleConfigs = [
  RoleConfig('admin', 'Admin', Icons.admin_panel_settings_outlined, AppColors.red, AppColors.redLight),
  RoleConfig('guru',  'Guru',  Icons.school_outlined,              AppColors.navy, AppColors.navyLight),
  RoleConfig('siswa', 'Siswa', Icons.people_outline,               AppColors.green, AppColors.greenLight),
];

final _usersProvider = FutureProvider.autoDispose.family<List<UserModel>, String>((ref, role) async {
  final data = await ApiClient.get('/admin/users', params: {'role': role, 'per_page': 200});
  return ((data['data'] as List?) ?? []).map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
});
final _levelFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

// ── Screen ──
class RoleUserListScreen extends ConsumerWidget {
  final String roleKey;
  const RoleUserListScreen({super.key, required this.roleKey});
  RoleConfig get cfg => roleConfigs.firstWhere((c) => c.key == roleKey);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(_usersProvider(roleKey));
    final levelFilter = ref.watch(_levelFilterProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text('${cfg.label} Users'),
        actions: [
          IconButton(icon: const Icon(Icons.add_circle_outline, size: 22), tooltip: 'Tambah ${cfg.label}', onPressed: () => _showCreateSheet(context, ref, roleKey)),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(_usersProvider(roleKey))),
        ]),
      body: Column(children: [
        if (roleKey == 'siswa')
          Container(color: AppColors.surface, padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: SingleChildScrollView(scrollDirection: Axis.horizontal,
              child: Row(children: ['Semua|', '10|Kelas 10', '11|Kelas 11', '12|Kelas 12'].map((e) {
                final parts = e.split('|');
                final v = parts[0]; final l = parts.length > 1 ? parts[1] : parts[0];
                final active = v == 'Semua' ? levelFilter == null : levelFilter == v;
                return GestureDetector(
                  onTap: () => ref.read(_levelFilterProvider.notifier).state = v == 'Semua' ? null : v,
                  child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: active ? cfg.color : AppColors.bg, borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: active ? cfg.color : AppColors.border)),
                    child: Text(l, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: active ? Colors.white : AppColors.ink3)),
                  ),
                );
              }).toList()),
            )),
        Expanded(child: users.when(
          loading: () => ListView(children: const [SkeletonListTile(), SkeletonListTile(), SkeletonListTile(), SkeletonListTile()]),
          error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(_usersProvider(roleKey))),
          data: (list) {
            var filtered = list;
            if (levelFilter != null && roleKey == 'siswa') filtered = list.where((u) => u.enrolledClasses.any((c) => c['level'] == levelFilter)).toList();
            if (filtered.isEmpty) return const EmptyState(title: 'Tidak ada user', icon: Icons.person_off_outlined);
            return ListView.builder(padding: const EdgeInsets.fromLTRB(12, 8, 12, 80), itemCount: filtered.length,
              itemBuilder: (_, i) => _UserCard(user: filtered[i], cfg: cfg, ref: ref));
          },
        )),
      ]),
    );
  }
}

// ── User Card ──
class _UserCard extends ConsumerWidget {
  final UserModel user; final RoleConfig cfg; final WidgetRef ref;
  const _UserCard({required this.user, required this.cfg, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = user;
    final actionColor = cfg.color;
    return Container(margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(14),
        child: InkWell(borderRadius: BorderRadius.circular(14), onTap: () => _showDetail(context, u, ref),
          child: Padding(padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(children: [
              CircleAvatar(radius: 22, backgroundColor: u.isActive ? cfg.colorLight : AppColors.bg,
                child: Text(u.initials, style: TextStyle(color: u.isActive ? cfg.color : AppColors.ink3, fontWeight: FontWeight.w700, fontSize: 14))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(u.name, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis)),
                  if (!u.isActive) ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(4)), child: Text('Nonaktif', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.red)))],
                ]),
                const SizedBox(height: 2),
                Text(u.email, style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
                if (u.role == 'guru' && u.classNames.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 3), child: Row(children: [
                  Icon(Icons.book_outlined, size: 11, color: actionColor), const SizedBox(width: 3),
                  Flexible(child: Text(u.classNames.join(', '), style: TextStyle(fontSize: 10, color: actionColor, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                ])),
                if (u.role == 'siswa' && u.levelLabel != null) Padding(padding: const EdgeInsets.only(top: 2), child: Row(children: [
                  Icon(Icons.format_list_numbered, size: 11, color: actionColor), const SizedBox(width: 3),
                  Text(u.levelLabel!, style: TextStyle(fontSize: 10.5, color: actionColor, fontWeight: FontWeight.w600)),
                ])),
              ])),
              // CRUD action icons row
              Row(mainAxisSize: MainAxisSize.min, children: [
                _act(Icons.edit_outlined, AppColors.navy, () => _editUser(context, u, ref)),
                if (u.role == 'siswa') _act(Icons.class_outlined, AppColors.navy, () => _updateKelas(context, u, ref)),
                _act(u.isActive ? Icons.toggle_off_outlined : Icons.toggle_on_outlined, u.isActive ? AppColors.ink3 : AppColors.green, () => _toggleStatus(context, u, ref)),
                _act(Icons.lock_reset, AppColors.amber, () => _gantiPassword(context, u)),
                if (u.role != 'admin') _act(Icons.delete_outline, AppColors.red, () => _deleteUser(context, u, ref)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _act(IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(width: 30, height: 30, child: IconButton(
      padding: EdgeInsets.zero, iconSize: 17, color: color,
      icon: Icon(icon), onPressed: onTap,
      splashRadius: 16,
    ));
  }
}

// ── Detail ──
void _showDetail(BuildContext context, UserModel u, WidgetRef ref) {
  final rc = u.role == 'admin' ? AppColors.red : (u.role == 'guru' ? AppColors.navy : AppColors.green);
  final rcl = u.role == 'admin' ? AppColors.redLight : (u.role == 'guru' ? AppColors.navyLight : AppColors.greenLight);
  showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 16), child: Row(children: [
            CircleAvatar(radius: 28, backgroundColor: u.isActive ? rcl : AppColors.bg,
              child: Text(u.initials, style: TextStyle(color: u.isActive ? rc : AppColors.ink3, fontWeight: FontWeight.w700, fontSize: 16))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(u.name, style: AppTextStyles.h4),
              const SizedBox(height: 2), Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: rcl, borderRadius: BorderRadius.circular(8)),
                  child: Text(u.role, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: rc))),
                const SizedBox(width: 8), Text(u.email, style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
              ]),
            ])),
          ])),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(20), child: Column(children: [
            _dr(Icons.person_outline, 'NIP/NIS', u.nip ?? u.nis ?? '-'),
            const SizedBox(height: 10),
            _dr(Icons.info_outline, 'Status', u.isActive ? 'Aktif' : 'Nonaktif', valueColor: u.isActive ? AppColors.green : AppColors.red),
            if (u.role == 'guru' && u.classRooms.isNotEmpty) ...[
              const SizedBox(height: 10), _dr(Icons.school_outlined, 'Mata Pelajaran', u.classRooms.map((c) => '${c['subject'] ?? ''}').join(', ')),
              const SizedBox(height: 10), _dr(Icons.format_list_numbered_outlined, 'Tingkat', 'Kelas ${u.classRooms.map((c) => c['level'] ?? '').where((l) => l.isNotEmpty).toSet().join(', ')}'),
              const SizedBox(height: 10), _dr(Icons.class_outlined, 'Kelas Diajar', u.classRooms.map((c) => '${c['name'] ?? ''}').join(', ')),
            ],
            if (u.role == 'siswa' && u.enrolledClasses.isNotEmpty) ...[
              const SizedBox(height: 10), _dr(Icons.format_list_numbered_outlined, 'Tingkat', 'Kelas ${u.enrolledClasses.map((c) => c['level'] ?? '').where((l) => l.isNotEmpty).toSet().join(', ')}'),
              const SizedBox(height: 10), _dr(Icons.class_outlined, 'Kelas', u.enrolledClasses.map((c) => '${c['name'] ?? ''} (${c['subject'] ?? ''})').join(', ')),
            ],
            if ((u.role == 'guru' && u.classRooms.isEmpty) || (u.role == 'siswa' && u.enrolledClasses.isEmpty)) ...[
              const SizedBox(height: 10), _dr(Icons.class_outlined, 'Kelas', 'Belum ditentukan'),
            ],
          ])),
          Container(padding: const EdgeInsets.fromLTRB(20, 12, 20, 24), decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
            child: Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => _gantiPassword(context, u), icon: const Icon(Icons.lock_reset, size: 16), label: const Text('Ganti Password', style: TextStyle(fontSize: 12)))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(onPressed: () => _toggleStatus(context, u, ref), icon: Icon(u.isActive ? Icons.block : Icons.check_circle_outline, size: 16), label: Text(u.isActive ? 'Nonaktifkan' : 'Aktifkan', style: const TextStyle(fontSize: 12)))),
            ]),
          ),
        ]),
      ),
    ),
  );
}

Widget _dr(IconData icon, String label, String value, {Color? valueColor}) {
  return Row(children: [
    Icon(icon, size: 16, color: AppColors.ink3), const SizedBox(width: 10),
    Text('$label: ', style: AppTextStyles.bodySmall),
    Expanded(child: Text(value, style: AppTextStyles.bodySmall.copyWith(color: valueColor ?? AppColors.ink, fontWeight: FontWeight.w500))),
  ]);
}

// ── Create Sheet ──
void _showCreateSheet(BuildContext context, WidgetRef ref, String roleKey) {
  final cfg = roleConfigs.firstWhere((c) => c.key == roleKey);
  final nameCtrl = TextEditingController(), emailCtrl = TextEditingController(), passCtrl = TextEditingController(), nipCtrl = TextEditingController();
  int? classId; final classesFuture = ApiClient.get('/admin/classes');
  showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => StatefulBuilder(builder: (ctx2, setS) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(height: MediaQuery.of(context).size.height * .78, decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: Column(children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(18,0,18,12), child: Row(children: [
            Row(children: [Icon(Icons.person_add, size: 18, color: cfg.color), const SizedBox(width: 8), Text('Tambah ${cfg.label} Baru', style: AppTextStyles.h4)]),
            const Spacer(),
            TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('Batal')),
          ])),
          const Divider(height: 1),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(18), child: Column(children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap *', prefixIcon: Icon(Icons.person_outline, size: 18))),
            const SizedBox(height: 12),
            TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email *', prefixIcon: Icon(Icons.email_outlined, size: 18))),
            const SizedBox(height: 12),
            TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password *', prefixIcon: Icon(Icons.lock_outline, size: 18))),
            const SizedBox(height: 12),
            TextField(controller: nipCtrl, decoration: InputDecoration(labelText: roleKey == 'siswa' ? 'NIS' : 'NIP', prefixIcon: Icon(Icons.badge_outlined, size: 18))),
            if (roleKey == 'siswa') ...[
              const SizedBox(height: 12),
              FutureBuilder<dynamic>(future: classesFuture, builder: (_, snap) {
                if (snap.connectionState != ConnectionState.done) return const LinearProgressIndicator(minHeight: 2);
                final classes = ((snap.data as Map<String, dynamic>?)??{'data':[]})['data'] as List? ?? [];
                return DropdownButtonFormField<int>(initialValue: classId,
                  decoration: const InputDecoration(labelText: 'Kelas Siswa *', prefixIcon: Icon(Icons.class_outlined, size: 18)),
                  items: classes.map((c) => DropdownMenuItem<int>(value: c['id'] as int, child: Text('${c['name']} · ${c['subject']}'))).toList(),
                  onChanged: (v) => setS(() => classId = v));
              }),
            ],
          ]))),
          Container(padding: const EdgeInsets.fromLTRB(18,12,18,24), decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
            child: ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty || passCtrl.text.isEmpty) { ScaffoldMessenger.of(ctx2).showSnackBar(const SnackBar(content: Text('Nama, email, password wajib diisi'))); return; }
                if (roleKey == 'siswa' && classId == null) { ScaffoldMessenger.of(ctx2).showSnackBar(const SnackBar(content: Text('Kelas wajib dipilih'))); return; }
                try {
                  final data = await ApiClient.post('/admin/users', data: {
                    'name': nameCtrl.text, 'email': emailCtrl.text, 'password': passCtrl.text, 'role': roleKey,
                    if (roleKey == 'siswa') 'nis': nipCtrl.text else 'nip': nipCtrl.text,
                  }) as Map<String, dynamic>;
                  if (roleKey == 'siswa' && classId != null) {
                    final user = data['user'] as Map<String, dynamic>;
                    await ApiClient.post('/guru/classes/$classId/students', data: {'student_ids': [user['id']]});
                  }
                  ref.invalidate(_usersProvider(roleKey));
                  if (ctx2.mounted) { Navigator.pop(ctx2); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User berhasil dibuat'))); }
                } catch (e) { if (ctx2.mounted) ScaffoldMessenger.of(ctx2).showSnackBar(SnackBar(content: Text(e.toString()))); }
              },
              child: const Text('Buat User')),
          ),
        ]),
      ),
    )),
  );
}

// ── Edit Sheet ──
void _editUser(BuildContext context, UserModel u, WidgetRef ref) {
  final nameCtrl = TextEditingController(text: u.name), emailCtrl = TextEditingController(text: u.email), nipCtrl = TextEditingController(text: u.nip ?? u.nis ?? ''), passCtrl = TextEditingController();
  int? classId = u.enrolledClasses.isNotEmpty ? u.enrolledClasses.first['id'] as int? : null;
  final classesFuture = ApiClient.get('/admin/classes');
  final cfg = roleConfigs.firstWhere((c) => c.key == u.role);
  showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => StatefulBuilder(builder: (ctx2, setS) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(height: MediaQuery.of(context).size.height * .65, decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: Column(children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(18,0,18,12), child: Row(children: [
            Row(children: [Icon(Icons.edit_outlined, size: 18, color: cfg.color), const SizedBox(width: 8), Text('Edit ${cfg.label}', style: AppTextStyles.h4)]),
            const Spacer(), TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('Batal')),
          ])),
          const Divider(height: 1),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(18), child: Column(children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap *', prefixIcon: Icon(Icons.person_outline, size: 18))),
            const SizedBox(height: 12),
            TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email *', prefixIcon: Icon(Icons.email_outlined, size: 18))),
            const SizedBox(height: 12),
            TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password Baru (opsional)', hintText: 'Kosongkan jika tidak diubah · min. 8 karakter', prefixIcon: Icon(Icons.lock_outline, size: 18))),
            const SizedBox(height: 12),
            TextField(controller: nipCtrl, decoration: InputDecoration(labelText: u.role == 'siswa' ? 'NIS' : 'NIP', prefixIcon: Icon(Icons.badge_outlined, size: 18))),
            if (u.role == 'siswa') ...[
              const SizedBox(height: 12),
              FutureBuilder<dynamic>(future: classesFuture, builder: (_, snap) {
                final classes = ((snap.data as Map<String, dynamic>?)??{'data':[]})['data'] as List? ?? [];
                if (snap.connectionState != ConnectionState.done) return const LinearProgressIndicator(minHeight: 2);
                return DropdownButtonFormField<int>(initialValue: classId, decoration: const InputDecoration(labelText: 'Kelas Siswa', prefixIcon: Icon(Icons.class_outlined, size: 18)),
                  items: classes.map((c) => DropdownMenuItem<int>(value: c['id'] as int, child: Text('${c['name']} · ${c['subject']}'))).toList(),
                  onChanged: (v) => setS(() => classId = v));
              }),
            ],
          ]))),
          Container(padding: const EdgeInsets.fromLTRB(18,12,18,24), decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
            child: ElevatedButton(onPressed: () async {
              if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty) { ScaffoldMessenger.of(ctx2).showSnackBar(const SnackBar(content: Text('Nama & email wajib diisi'))); return; }
              if (passCtrl.text.isNotEmpty && passCtrl.text.length < 8) { ScaffoldMessenger.of(ctx2).showSnackBar(const SnackBar(content: Text('Password minimal 8 karakter'))); return; }
              try {
                await ApiClient.put('/admin/users/${u.id}/update', data: {'name': nameCtrl.text, 'email': emailCtrl.text, 'role': u.role, if (u.role == 'siswa') 'nis': nipCtrl.text else 'nip': nipCtrl.text, if (passCtrl.text.isNotEmpty) 'password': passCtrl.text});
                if (u.role == 'siswa') await ApiClient.put('/admin/users/${u.id}/class', data: {'class_id': classId ?? 0});
                ref.invalidate(_usersProvider(u.role));
                if (ctx2.mounted) { Navigator.pop(ctx2); ScaffoldMessenger.of(ctx2).showSnackBar(const SnackBar(content: Text('User berhasil diupdate'))); }
              } catch (e) { if (ctx2.mounted) ScaffoldMessenger.of(ctx2).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.red)); }
            }, child: const Text('Simpan')),
          ),
        ]),
      ),
    )),
  );
}

void _gantiPassword(BuildContext context, UserModel u) {
  final ctrl = TextEditingController();
  showDialog(context: context, builder: (ctx) => AlertDialog(
    title: Row(children: [Icon(Icons.lock_reset, size: 20, color: AppColors.amber), const SizedBox(width: 8), Text('Ganti Password')]),
    content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(u.name, style: AppTextStyles.bodySmall), const SizedBox(height: 10),
      TextField(controller: ctrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password Baru', hintText: 'Min. 8 karakter')),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
      ElevatedButton(onPressed: () async {
        if (ctrl.text.length < 8) return;
        try {
          await ApiClient.patch('/admin/users/${u.id}/ganti-password', data: {'password': ctrl.text});
          if (ctx.mounted) Navigator.pop(ctx);
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password ${u.name} diganti')));
        } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.red)); }
      }, style: ElevatedButton.styleFrom(minimumSize: const Size(0,0), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)), child: const Text('Ganti')),
    ],
  ));
}

void _toggleStatus(BuildContext context, UserModel u, WidgetRef ref) async {
  try {
    await ApiClient.patch('/admin/users/${u.id}/toggle-status');
    ref.invalidate(_usersProvider(u.role));
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status ${u.name} diubah')));
  } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.red)); }
}

void _deleteUser(BuildContext context, UserModel u, WidgetRef ref) async {
  final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
    title: Row(children: [Icon(Icons.delete_outline, size: 20, color: AppColors.red), const SizedBox(width: 8), const Text('Hapus User?')]),
    content: Text('Hapus akun "${u.name}"? Tindakan tidak dapat dibatalkan.'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
      ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, minimumSize: const Size(0,0), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)), child: const Text('Hapus')),
    ],
  ));
  if (ok != true) return;
  try {
    await ApiClient.delete('/admin/users/${u.id}');
    ref.invalidate(_usersProvider(u.role));
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${u.name} dihapus')));
  } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.red)); }
}

void _updateKelas(BuildContext context, UserModel u, WidgetRef ref) {
  int? classId; final classesFuture = ApiClient.get('/admin/classes');
  showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => StatefulBuilder(builder: (ctx2, setS) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(padding: const EdgeInsets.all(18), decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          Row(children: [Icon(Icons.class_outlined, size: 18, color: AppColors.navy), const SizedBox(width: 8), Text('Pindah Kelas — ${u.name}', style: AppTextStyles.h4)]),
          const SizedBox(height: 14),
          FutureBuilder<dynamic>(future: classesFuture, builder: (_, snap) {
            if (snap.connectionState != ConnectionState.done) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
            final classes = ((snap.data as Map<String, dynamic>)['data'] as List? ?? []);
            return DropdownButtonFormField<int>(decoration: const InputDecoration(labelText: 'Pilih Kelas', prefixIcon: Icon(Icons.class_outlined, size: 18)),
              items: classes.map((c) => DropdownMenuItem<int>(value: c['id'] as int, child: Text('${c['name']} · ${c['subject']}'))).toList(),
              onChanged: (v) => setS(() => classId = v));
          }),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () async {
            if (classId == null) { ScaffoldMessenger.of(ctx2).showSnackBar(const SnackBar(content: Text('Pilih kelas dulu'))); return; }
            try {
              await ApiClient.put('/admin/users/${u.id}/class', data: {'class_id': classId});
              ref.invalidate(_usersProvider(u.role));
              if (ctx2.mounted) { Navigator.pop(ctx2); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kelas berhasil diperbarui'))); }
            } catch (e) { if (ctx2.mounted) ScaffoldMessenger.of(ctx2).showSnackBar(SnackBar(content: Text(e.toString()))); }
          }, child: const Text('Simpan')),
          const SizedBox(height: 8),
        ]),
      ),
    )),
  );
}
