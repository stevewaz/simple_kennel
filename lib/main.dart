import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/tenant_settings_service.dart';
import 'services/theme_service.dart';
import 'services/runs_service.dart';
import 'services/prefs_service.dart';
import 'providers/app_provider.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/invoices_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true);
  await PrefsService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        Provider(create: (_) => AuthService()),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
      ],
      child: const RunbookApp(),
    ),
  );
}

class RunbookApp extends StatelessWidget {
  const RunbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();
    return MaterialApp(
      title: 'Runbook',
      debugShowCheckedModeBanner: false,
      theme: theme.buildTheme(),
      home: SplashScreen(nextScreen: (_) => const AuthGate()),
    );
  }
}

/// Branches to [LoginScreen] or [MainShell] based on Firebase Auth state,
/// and keeps them switching live if the user signs out from deep inside
/// [MainShell] (e.g. Settings). A fresh [TenantSettingsService]/
/// [DatabaseService]/[AppProvider]/[RunsService] set is constructed per
/// signed-in user — keyed on their uid — so a different business logging
/// in later on the same device can never reuse the previous tenant's data.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    if (user == null) return const LoginScreen();
    return MultiProvider(
      key: ValueKey(user.uid),
      providers: [
        ChangeNotifierProvider<TenantSettingsService>(
          create: (_) => TenantSettingsService(user.uid),
        ),
        ChangeNotifierProvider<RunsService>(
          create: (context) => RunsService(context.read<TenantSettingsService>()),
        ),
        ChangeNotifierProvider<AppProvider>(
          create: (context) => AppProvider(
            DatabaseService(tenantId: user.uid),
            context.read<TenantSettingsService>(),
          ),
        ),
      ],
      child: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  static const _labels = [
    'Dashboard', 'Schedule', 'Customers', 'Invoices',
  ];

  static const _icons = [
    Icons.dashboard_outlined,
    Icons.calendar_month_outlined,
    Icons.people_outlined,
    Icons.receipt_long_outlined,
  ];

  static const _selectedIcons = [
    Icons.dashboard,
    Icons.calendar_month,
    Icons.people,
    Icons.receipt_long,
  ];

  static const _screens = [
    DashboardScreen(),
    ScheduleScreen(),
    CustomersScreen(),
    InvoicesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          _labels[_tab],
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.summarize_outlined, color: Colors.white),
            tooltip: 'Reports',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: theme.cardBgColor,
        indicatorColor: theme.primaryColor.withValues(alpha: 0.2),
        destinations: List.generate(
          4,
          (i) => NavigationDestination(
            icon: Icon(_icons[i], color: theme.subtextColor),
            selectedIcon: Icon(_selectedIcons[i], color: theme.primaryColor),
            label: _labels[i],
          ),
        ),
      ),
    );
  }
}
