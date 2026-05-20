import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'landing_page.dart';
import 'dashboard_admin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://apxbviuerlkssbcgefpj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFweGJ2aXVlcmxrc3NiY2dlZnBqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzMjgxNDksImV4cCI6MjA5MzkwNDE0OX0.dGuIG7Tvlcqvj226rsjLAF4Xp680EYkxM1rhkmwNF-A',
    authOptions: const FlutterAuthClientOptions(
      authFlowType:
          AuthFlowType.pkce, // Gunakan PKCE untuk keamanan Web yang lebih baik
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Bank Sampah - Wadah Runtah',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;

        if (session == null) {
          return LandingPage();
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: Supabase.instance.client
              .from('profiles')
              .select('role')
              .eq('id', session.user.id)
              .maybeSingle(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final role = roleSnapshot.data?['role'];

            // Logika pengecekan role
            if (role == 'admin') return DashboardAdminPage();
            if (role == 'tenant') return DashboardTenantPage();
            return DashboardMemberPage();
          },
        );
      },
    );
  }
}

// --- DEFINISI KELAS CADANGAN (PLACEHOLDER) AGAR TIDAK ERROR ---
class DashboardTenantPage extends StatelessWidget {
  const DashboardTenantPage({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text("Dashboard Tenant")));
}

class DashboardMemberPage extends StatelessWidget {
  const DashboardMemberPage({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text("Dashboard Member")));
}
