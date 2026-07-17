import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/guru/presentation/screens/guru_dashboard_screen.dart';
import '../../features/guru/presentation/screens/ujian_management_screen.dart';
import '../../features/guru/presentation/screens/rekap_nilai_screen.dart';
import '../../features/guru/presentation/screens/soal_screen.dart';
import '../../features/guru/presentation/screens/paket_soal_screen.dart';
import '../../features/guru/presentation/screens/input_soal_screen.dart';
import '../../features/siswa/presentation/screens/siswa_dashboard_screen.dart';
import '../../features/siswa/presentation/screens/ujian_screen.dart';
import '../../features/siswa/presentation/screens/hasil_screen.dart';
import '../../features/siswa/presentation/screens/riwayat_screen.dart';
import '../../features/siswa/data/siswa_models.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/user_management_screen.dart';
import '../../features/admin/presentation/screens/role_user_list_screen.dart';
import '../../features/admin/presentation/screens/admin_class_management_screen.dart';
import '../../features/admin/presentation/screens/admin_exam_screen.dart';
import '../../features/admin/presentation/screens/admin_violations_screen.dart';
import '../../features/admin/presentation/screens/admin_activity_log_screen.dart';
import '../../features/shared/presentation/screens/notification_screen.dart';
import '../../features/shared/presentation/screens/profile_screen.dart';
import '../storage/secure_storage.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) async {
    final loggedIn = await SecureStorage.isLoggedIn();
    final loc      = state.matchedLocation;

    if (!loggedIn && loc != '/login' && loc != '/splash') return '/login';
    return null;
  },
  routes: [
    GoRoute(path: '/splash',          builder: (_, _) => const _SplashScreen()),
    GoRoute(path: '/login',           builder: (_, _) => const LoginScreen()),

    // ── GURU ─────────────────────────────────────────────
    ShellRoute(
      builder: (_, _, child) => _GuruShell(child: child),
      routes: [
        GoRoute(path: '/guru/dashboard', builder: (_, _) => const GuruDashboardScreen()),
        GoRoute(path: '/guru/input-soal',   builder: (_, _) => const InputSoalScreen()),
        GoRoute(path: '/guru/exams',        builder: (_, _) => const UjianManagementScreen()),
        GoRoute(path: '/guru/rekap-nilai',  builder: (_, _) => const RekapNilaiScreen()),
        GoRoute(path: '/guru/soal',         builder: (_, _) => const SoalScreen()),
        GoRoute(path: '/guru/paket-soal',   builder: (_, _) => const PaketSoalScreen()),
      ],
    ),
    // Guru routes tanpa shell (full screen)
    GoRoute(path: '/guru/exam/create', builder: (_, _) => const UjianManagementScreen()),
    GoRoute(path: '/guru/notifications', builder: (_, _) => const NotificationScreen()),
    GoRoute(path: '/guru/profile',       builder: (_, _) => const ProfileScreen()),

    // ── SISWA ─────────────────────────────────────────────
    ShellRoute(
      builder: (_, _, child) => _SiswaShell(child: child),
      routes: [
        GoRoute(path: '/siswa/dashboard', builder: (_, _) => const SiswaDashboardScreen()),
        GoRoute(path: '/siswa/riwayat',   builder: (_, _) => const RiwayatScreen()),
      ],
    ),
    // Siswa routes tanpa shell (full screen)
    GoRoute(
      path: '/siswa/exam/:examId',
      builder: (_, state) => UjianScreen(examId: int.parse(state.pathParameters['examId']!)),
    ),
    GoRoute(
      path: '/siswa/result/:sessionId',
      builder: (_, state) => HasilScreen(
        sessionId: int.parse(state.pathParameters['sessionId']!),
        result:    state.extra as ExamResultModel?,
      ),
    ),
    GoRoute(path: '/siswa/notifications', builder: (_, _) => const NotificationScreen()),
    GoRoute(path: '/siswa/profile',       builder: (_, _) => const ProfileScreen()),

    // ── ADMIN ─────────────────────────────────────────────
    ShellRoute(
      builder: (_, _, child) => _AdminShell(child: child),
      routes: [
        GoRoute(path: '/admin/dashboard', builder: (_, _) => const AdminDashboardScreen()),
        GoRoute(path: '/admin/users',         builder: (_, _) => const UserManagementScreen()),
        GoRoute(path: '/admin/users/:role',    builder: (_, state) => RoleUserListScreen(
          roleKey: state.pathParameters['role'] ?? 'siswa',
        )),
        GoRoute(path: '/admin/kelas',     builder: (_, _) => const AdminClassManagementScreen()),
        GoRoute(path: '/admin/exams',         builder: (_, _) => const AdminExamScreen()),
        GoRoute(path: '/admin/violations',    builder: (_, _) => const AdminViolationsScreen()),
        GoRoute(path: '/admin/activity-log',  builder: (_, _) => const AdminActivityLogScreen()),
      ],
    ),
    GoRoute(path: '/admin/notifications', builder: (_, _) => const NotificationScreen()),
    GoRoute(path: '/admin/profile',       builder: (_, _) => const ProfileScreen()),
  ],
  errorBuilder: (_, state) => Scaffold(
    body: Center(child: Text('Halaman tidak ditemukan: ${state.error}')),
  ),
);

// ── Splash ────────────────────────────────────────────
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();
  @override
  State<_SplashScreen> createState() => __SplashScreenState();
}

class __SplashScreenState extends State<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 1600));
    final loggedIn = await SecureStorage.isLoggedIn();
    if (!mounted) return;

    if (!loggedIn) {
      context.go('/login');
      return;
    }

    final role = await SecureStorage.getRole();
    if (!mounted) return;

    switch (role) {
      case 'guru':
        context.go('/guru/dashboard');
        break;
      case 'siswa':
        context.go('/siswa/dashboard');
        break;
      case 'admin':
        context.go('/admin/dashboard');
        break;
      default:
        context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B2242), Color(0xFF173A6A)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 172,
                height: 172,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'assets/images/smk_parittiga_logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Center(child: Icon(Icons.school, color: Color(0xFF0B2242), size: 88)),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text('SMKN 1 Parittiga',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 0.2),
              ),
              const SizedBox(height: 8),
              const Text('Sistem Ujian Online',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFB8D1F0), fontSize: 14),
              ),
              const SizedBox(height: 28),
              const SizedBox(
                width: 96,
                height: 4,
                child: LinearProgressIndicator(
                  backgroundColor: Color(0xFF193660),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ── Guru Shell (bottom nav) ───────────────────────────
class _GuruShell extends StatelessWidget {
  final Widget child;
  const _GuruShell({required this.child});
  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = ['/guru/dashboard','/guru/input-soal','/guru/exams','/guru/rekap-nilai'].indexOf(loc).clamp(0, 3);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) {
          const routes = ['/guru/dashboard','/guru/input-soal','/guru/exams','/guru/rekap-nilai'];
          context.go(routes[i]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined),  selectedIcon: Icon(Icons.dashboard),     label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.edit_note_outlined),  selectedIcon: Icon(Icons.edit_note),     label: 'Input Soal'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Jadwal Ujian'),
          NavigationDestination(icon: Icon(Icons.grade_outlined),      selectedIcon: Icon(Icons.grade),       label: 'Rekap Nilai'),
        ],
      ),
    );
  }
}

// ── Siswa Shell (bottom nav) ──────────────────────────
class _SiswaShell extends StatelessWidget {
  final Widget child;
  const _SiswaShell({required this.child});
  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = ['/siswa/dashboard','/siswa/riwayat'].indexOf(loc).clamp(0, 1);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) {
          const routes = ['/siswa/dashboard','/siswa/riwayat'];
          context.go(routes[i]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined),    selectedIcon: Icon(Icons.home),    label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'Riwayat'),
        ],
      ),
    );
  }
}

// ── Admin Shell (bottom nav) ──────────────────────────
class _AdminShell extends StatelessWidget {
  final Widget child;
  const _AdminShell({required this.child});
  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = ['/admin/dashboard','/admin/users','/admin/kelas','/admin/exams'].indexOf(loc).clamp(0, 3);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) {
          const routes = ['/admin/dashboard','/admin/users','/admin/kelas','/admin/exams'];
          context.go(routes[i]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.people_outline),     selectedIcon: Icon(Icons.people),    label: 'Pengguna'),
          NavigationDestination(icon: Icon(Icons.class_outlined),      selectedIcon: Icon(Icons.class_),     label: 'Kelas'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined),selectedIcon: Icon(Icons.assignment), label: 'Ujian'),
        ],
      ),
    );
  }
}
