import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/runs_service.dart';
import '../services/tenant_settings_service.dart';

/// Re-exposes the already-created [AppProvider]/[TenantSettingsService]/
/// [RunsService] instances to a new route or dialog/bottom-sheet subtree.
///
/// These services are provided once, per signed-in session, inside
/// `AuthGate`'s tenant-scoped `MultiProvider` (see main.dart). Anything
/// shown via `Navigator.push`, `showDialog`, or `showModalBottomSheet`
/// lands in a *sibling* branch of the app's single `Overlay` — not a
/// descendant of that `MultiProvider` — so a fresh `context.read`/`watch`
/// from inside the new route/dialog fails with "Provider not found",
/// even though the calling context (where `showDialog` etc. was invoked)
/// can see it fine. Wrap the `builder` with this whenever the pushed
/// content (or anything nested inside it) needs live access to these
/// services, rather than a one-off snapshot passed via constructor.
Widget withTenantProviders(BuildContext context, Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TenantSettingsService>.value(
          value: context.read<TenantSettingsService>()),
      ChangeNotifierProvider<RunsService>.value(
          value: context.read<RunsService>()),
      ChangeNotifierProvider<AppProvider>.value(
          value: context.read<AppProvider>()),
    ],
    child: child,
  );
}
