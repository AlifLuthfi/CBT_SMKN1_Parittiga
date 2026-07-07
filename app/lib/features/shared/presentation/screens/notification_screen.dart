import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_widgets.dart';

class NotificationModel {
  final int id; final String title, message, type; final bool isRead; final String createdAt;
  const NotificationModel({required this.id, required this.title, required this.message, required this.type, required this.isRead, required this.createdAt});
  factory NotificationModel.fromJson(Map<String, dynamic> j) => NotificationModel(
    id:        j['id']         as int,
    title:     j['title']      as String,
    message:   j['message']    as String,
    type:      j['type']       as String? ?? 'info',
    isRead:    j['read_at']    != null,
    createdAt: j['created_at'] as String? ?? '',
  );
}

final _notifProvider = FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  try {
    final data = await ApiClient.get('/notifications');
    final list = (data['data'] as List?) ?? [];
    return list.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return _demoNotifs;
  }
});

const _demoNotifs = [
  NotificationModel(id:1, title:'Ujian Baru Diaktifkan', message:'UH 1 Aljabar Dasar telah diaktifkan oleh Guru Budi. Segera kerjakan!', type:'info', isRead:false, createdAt:'5 menit lalu'),
  NotificationModel(id:2, title:'Hasil Ujian Tersedia', message:'Nilai UH Ekonomi Mikro sudah bisa dilihat. Klik untuk melihat pembahasan.', type:'ok', isRead:false, createdAt:'1 jam lalu'),
  NotificationModel(id:3, title:'Jadwal Ujian Diperbarui', message:'UTS Fisika dijadwalkan ke 10 Juni 2026 pukul 08:00', type:'warn', isRead:true, createdAt:'2 hari lalu'),
  NotificationModel(id:4, title:'Pelanggaran Terdeteksi', message:'Siswa Ahmad Naufal terdeteksi pindah tab 2x pada UH Matematika', type:'err', isRead:true, createdAt:'3 hari lalu'),
];

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});
  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final notifs = ref.watch(_notifProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          TextButton(
            onPressed: () async {
              try { await ApiClient.patch('/notifications/read-all'); } catch (_) {}
              ref.invalidate(_notifProvider);
            },
            child: const Text('Tandai Semua', style: TextStyle(color: AppColors.navy, fontSize: 13)),
          ),
        ],
      ),
      body: Column(children: [
        // Filter
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            _chip('all',    'Semua'),
            _chip('unread', 'Belum Dibaca'),
            _chip('info',   'Info'),
            _chip('ok',     'Sukses'),
            _chip('warn',   'Peringatan'),
          ]),
        ),
        // List
        Expanded(child: notifs.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e,_) => ErrorState(message: e.toString()),
          data:    (list) {
            final filtered = _filter == 'all'    ? list
                : _filter == 'unread' ? list.where((n) => !n.isRead).toList()
                : list.where((n) => n.type == _filter).toList();
            if (filtered.isEmpty) return EmptyState(
              title: _filter == 'unread' ? 'Semua notifikasi sudah dibaca' : 'Tidak ada notifikasi',
              icon:  Icons.notifications_none_outlined,
            );
            return ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) => _notifTile(filtered[i]),
            );
          },
        )),
      ]),
    );
  }

  Widget _chip(String val, String label) {
    final active = _filter == val;
    return GestureDetector(
      onTap: () => setState(() => _filter = val),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.navy : AppColors.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.navy : AppColors.border),
        ),
        child: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: active ? Colors.white : AppColors.ink3)),
      ),
    );
  }

  Widget _notifTile(NotificationModel n) {
    final cfg = {
      'info': (AppColors.skyLight,   AppColors.sky,   Icons.info_outline),
      'ok':   (AppColors.greenLight, AppColors.green, Icons.check_circle_outline),
      'warn': (AppColors.amberLight, AppColors.amber, Icons.warning_amber_outlined),
      'err':  (AppColors.redLight,   AppColors.red,   Icons.error_outline),
    }[n.type] ?? (AppColors.navyLight, AppColors.navy, Icons.notifications_outlined);

    return Dismissible(
      key: Key('notif_${n.id}'),
      direction: DismissDirection.endToStart,
      background: Container(color: AppColors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white)),
      onDismissed: (_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifikasi dihapus')));
      },
      child: GestureDetector(
        onTap: () async {
          try { await ApiClient.patch('/notifications/${n.id}'); } catch (_) {}
          ref.invalidate(_notifProvider);
        },
        child: Container(
          decoration: BoxDecoration(
            color: n.isRead ? AppColors.surface : AppColors.navyLight,
            border: const Border(bottom: BorderSide(color: AppColors.border)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: cfg.$1, borderRadius: BorderRadius.circular(9)),
              child: Icon(cfg.$3, size: 18, color: cfg.$2)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(n.title, style: AppTextStyles.body.copyWith(fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600, color: AppColors.ink, fontSize: 13.5))),
                if (!n.isRead) Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.navy, shape: BoxShape.circle)),
              ]),
              const SizedBox(height: 3),
              Text(n.message, style: AppTextStyles.bodySmall.copyWith(height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(n.createdAt, style: AppTextStyles.bodySmall.copyWith(fontSize: 10.5)),
            ])),
          ]),
        ),
      ),
    );
  }
}
