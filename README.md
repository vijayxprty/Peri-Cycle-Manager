# PeriBuds 🌹

**Your period, predicted gently.**

PeriBuds is a free, fully offline period tracker for Android and iOS — periods,
ovulation and fertile window, your own diet chart with reminders, and reports
you can share with your doctor. No account, no cloud, no ads.

- 🌹 **Next period, predicted** — expected date with days to go; learns from your cycles
- 📅 **Calendar** — mark a period by start and end date in one tap
- 🥗 **Diet chart** — build your own meals, repeat per day, reminders for every meal
- 📊 **Reports** — average cycle/period length, history with month & year filters, PDF for your doctor
- 🔔 **Discreet reminders** — gentle wording, never the word "period" in a notification
- ✈️ **Travel mode** — warns if a period overlaps a trip, with a pack-pads checklist
- 🔒 **Private by design** — everything stays on your phone

## Download

- **Android:** [peribuds-1.0.6.apk](https://github.com/vijayxprty/peribuds/releases/download/v1.0.6/peribuds-1.0.6.apk) — install right over any earlier version, your data stays.
  Or visit the landing page: https://vijayxprty.github.io/peribuds/
- **iPhone:** the .ipa is built on a Mac (`flutter build ipa --no-codesign`) and will be added here for sideloading.

## Build from source

Flutter 3.35.7, Dart 3.9.2. The Android release build uses a local Gradle 8.12
(the Gradle wrapper can't download its distribution in this sandbox):

```bash
export PATH="$HOME/flutter/bin:$PATH" JAVA_HOME=$HOME/jdk17 \
  ANDROID_HOME=$HOME/android-sdk ANDROID_SDK_ROOT=$HOME/android-sdk \
  GRADLE_USER_HOME=$HOME/.gradle
cd app/android
~/gradle-8.12/bin/gradle assembleRelease --no-daemon --console=plain
# output: app/build/app/outputs/flutter-apk/app-release.apk
```

`flutter analyze` clean, `flutter test` 5/5. Release signing uses a local
keystore (`app/android/app/peribuds-release.keystore`, never committed) with
passwords in `app/android/key.properties` (also never committed).

## Privacy

No account, no cloud, no analytics, no ads. All data is stored locally on the
device. Predictions are estimates from the cycles you log — not medical advice.

Made with ♥ by Vijay Mamta Sahani — [@momentswithvms](https://www.instagram.com/momentswithvms/)
