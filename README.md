# Runbook

A kennel management app for small boarding businesses — tracks customers, pets, bookings, and invoices in one place.

**Try the latest version:** https://stevewaz.github.io/simple_kennel/

## What it does

- **Dashboard** — today's occupancy, check-ins/check-outs (AM/PM), and upcoming bookings at a glance
- **Schedule** — a run-by-day grid for booking pets in and out, with configurable runs (count + names)
- **Customers** — customer records with multiple pets each, breed autocomplete, and paperwork photo attachments
- **Invoices** — draft invoices auto-generated on check-in, line items pulled from a service catalog, PDF export/printing
- **Settings** — business branding, nightly rate, tax rate, run configuration, light/dark theme

## Data & platforms

Runs on iOS, Android, macOS, and Web. Everything is stored locally on-device — no account, no cloud, no login:

- iOS / Android / macOS / desktop: [Isar](https://isar.dev/) embedded database
- Web: a simple local JSON store (`localStorage`), intended for quick testing rather than daily production use

## Development

Standard Flutter project. After cloning:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```
