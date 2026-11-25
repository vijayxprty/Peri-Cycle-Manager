# Peri Cycle Manager — PeriBuds 🌹

**Your cycle, food and daily wellbeing in one private app.**

PeriBuds is a free, fully offline period and wellbeing tracker for Android and iOS. No account, no cloud, no ads.

## Current version

- **v1.1.0** adds automatic phone step counting, calories burned estimates, personal step goals, water intake logging and a Settings destination.
- The existing cycle predictions, Calendar, Diet, Reports, travel tools, reminders, and local records remain part of the app.
- Steps display in 8-step increments. The goal can be any positive whole number. Water amount and target are user controlled.

## Preserved version

- The `backup-of-working-version` branch and tag preserve the existing **v1.0.11+12** source before wellbeing changes.
- `main` is the new development version, based on that backup.
- Flutter app source: [`app/`](app/)

## Existing PeriBuds features

- 🌹 **Cycle predictions** — expected date and cycle phase based on periods you log.
- 📅 **Calendar** — mark a period by start and end date.
- 🥗 **Diet chart** — build meals, repeat per day, and set meal reminders.
- 📊 **Reports** — cycle history, averages, filters and PDF sharing.
- 🔔 **Discreet reminders** — gentle wording in notifications.
- ✈️ **Travel mode** — trip overlap notices and a packing checklist.
- 🔒 **Private by design** — records stay in local app storage.

## Build from source

Flutter 3.35.7 and Dart 3.9.2. From `app/`, run `flutter pub get`, then `flutter run` or `flutter build apk --release`.

## Privacy

No account, cloud sync, analytics or ads. Data is stored locally on the device. Cycle predictions and calories are estimates, not medical advice.
