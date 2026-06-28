import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/database_service.dart';
import 'services/theme_service.dart';
import 'services/runs_service.dart';
import 'services/prefs_service.dart';
import 'services/pocketbase_service.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/invoices_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PrefsService.init();
  await PocketBaseService.init();

  final db = DatabaseService(PocketBaseService.client);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => RunsService()),
        ChangeNotifierProvider(create: (_) => AppProvider(db)),
      ],
      child: const PawBookApp(),
    ),
  );
}

class PawBookApp extends StatelessWidget {
  const PawBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();
    return MaterialApp(
      title: 'PawBook',
      debugShowCheckedModeBanner: false,
      theme: theme.buildTheme(),
      home: SplashScreen(nextScreen: (_) => const MainShell()),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _loggedIn = false;
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
    _loggedIn = PocketBaseService.isLoggedIn;
    if (_loggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AppProvider>().loadAll();
      });
    }
  }

  void _onLogin() {
    setState(() => _loggedIn = true);
    context.read<AppProvider>().loadAll();
  }


  @override
  Widget build(BuildContext context) {
    if (!_loggedIn) {
      return LoginScreen(onLogin: _onLogin);
    }

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
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
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
