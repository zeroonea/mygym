# MyGym 🏋️

A personal gym-training tracker for Android, built with Flutter. Log your
workouts, record the **weight, sets and reps** for every exercise, and watch
your strength progress over time.

## Features

- **Fast in-workout logging** — start a workout, add exercises, and log each set
  with a quick +/- weight/reps pad. "Save & next" logs set after set without
  leaving the pad.
- **Exercise library** — 50+ common exercises pre-loaded and grouped by muscle
  group; add your own custom exercises too.
- **History** — every workout saved locally, with date, total sets and volume.
- **Progress charts** — per-exercise graphs of estimated 1RM, top-set weight and
  volume per session, plus your personal bests.
- **Offline & private** — all data is stored in a local SQLite database on your
  phone. Nothing is uploaded anywhere.

## Getting the app on your phone

The APK is built automatically in the cloud by GitHub Actions (no Android
Studio or local SDK needed).

1. Go to the repo's **Releases** page and open the latest **MyGym build**.
2. On your Android phone, download the `mygym-*.apk` asset.
3. Open the downloaded file. If prompted, allow your browser/file manager to
   *install unknown apps* (Settings → Apps → Special access → Install unknown
   apps), then tap **Install**.

You can also trigger a build manually from the **Actions** tab → *Build APK* →
*Run workflow*.

## Tech

- Flutter (Material 3), `provider` for state
- `sqflite` for local persistence
- `fl_chart` for progress graphs

## Developing locally

```bash
flutter pub get
flutter run          # run on a connected device/emulator
flutter analyze      # static analysis
flutter test         # unit tests
flutter build apk --release
```

The release build is signed with the debug key so the APK installs directly —
fine for personal use. To ship to the Play Store you'd add a real signing
config in `android/app/build.gradle.kts`.
