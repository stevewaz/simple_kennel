# Runbook

A kennel management app for small boarding businesses — tracks customers, pets, bookings, and invoices in one place.

**Try the latest version:** https://stevewaz.github.io/simple_kennel/

## What it does

- **Dashboard** — today's occupancy, check-ins/check-outs (AM/PM), and upcoming bookings at a glance
- **Schedule** — a run-by-day grid for booking pets in and out, with configurable runs (count + names)
- **Customers** — customer records with multiple pets each, breed autocomplete, and paperwork photo attachments
- **Invoices** — draft invoices auto-generated on check-in, line items pulled from a service catalog, PDF export/printing
- **Reports** — exportable payments report for bookkeeping, plus a printable "run sheet" for staff at check-in
- **Settings** — business branding, nightly rate, tax rate, run configuration, light/dark theme

## Data & platforms

Runs on iOS, Android, macOS, and Web. Each business signs in with one shared login and gets its own fully isolated data, synced live across all of that business's devices via [Firebase](https://firebase.google.com/) (Auth + Firestore). Firestore's offline cache means the app keeps working without a connection — writes made offline sync once you're back online.

## Development

Standard Flutter project. After cloning:

```bash
flutter pub get
flutter run
```

Requires a Firebase project (Firestore + Email/Password Auth enabled) and `lib/firebase_options.dart` generated via `flutterfire configure`.
