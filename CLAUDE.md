# CLAUDE.md — MyGym

Guidance for AI agents (and humans) working on this repo.

## What this is

**MyGym** is a personal Android **gym-training tracker** built with **Flutter**
(Material 3). It logs workouts with **weight × reps per set** (with per-set
timestamps + rest timers), keeps history, shows per-exercise progress charts,
and has an exercise library with animated demos and a muscle body-map. It also
tracks **body metrics** (weight/measurements → BMI, BMR, TDEE, body-fat %, lean
mass, target weight + macro targets) and has a **food macro search** backed by
Open Food Facts.

- Package / applicationId: `com.zeroonea.mygym`
- Development branch: `claude/gym-tracker-android-app-gc9ngm`
- Owner: personal use (not Play Store).

## ⚠️ Critical build constraint (read first)

This project is developed in the **Claude Code web** sandbox, whose network
policy **blocks Google's servers** (`dl.google.com`, `maven.google.com`). That
means **you cannot build an APK inside the container** — the Android SDK,
Android Gradle Plugin and AndroidX all live behind those hosts.

What *is* reachable from the container:
- `storage.googleapis.com` → the **Flutter SDK** can be downloaded.
- `pub.dev` → `flutter pub get` works.
- `raw.githubusercontent.com` → dataset/enrichment fetches work.

**So: APKs are built in the cloud by GitHub Actions**, never locally. Locally we
only *validate* (analyze/test).

### Local validation workflow (in the sandbox)

```bash
# Flutter isn't preinstalled; fetch it (only storage.googleapis.com is allowed):
curl -sS https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.4-stable.tar.xz -o /tmp/f.tar.xz
tar xf /tmp/f.tar.xz -C /opt
export PATH="/opt/flutter/bin:$PATH"
git config --global --add safe.directory /opt/flutter

flutter pub get
flutter analyze     # MUST be clean — CI runs this and fails on any issue
flutter test
# NOTE: `flutter build apk` will FAIL here (needs dl.google.com). Do not try.
```

Always get `flutter analyze` to **"No issues found"** before pushing — the CI
`analyze` step is strict (fixed the `unnecessary_underscores` lint by using
wildcard `_` params in image callbacks).

## Build & release (GitHub Actions)

- Workflow: `.github/workflows/build.yml`. On every push to `main`/`master`/
  `claude/**` (and manual dispatch) it runs analyze + test, builds a **release
  APK**, and publishes it to a **GitHub Release** tagged `build-<run_number>`
  (marked latest). Download link pattern:
  `https://github.com/zeroonea/mygym/releases/download/build-<n>/mygym-b<n>.apk`
- After pushing, watch the run via the GitHub MCP tools
  (`mcp__github__actions_list` / `get_job_logs`) and drive it to green.

### Signing (so APKs update in place)

Every build is signed with a **committed** keystore so installs update over each
other (a fresh CI debug key each run would force uninstall-first):
- `android/app/mygym-release.jks` (force-added; `**/*.jks` is gitignored)
- config in `android/app/build.gradle.kts` → `signingConfigs.release`
  (storePassword/keyPassword `mygymkey`, alias `mygym`).
- This is a **personal** key intentionally committed to a public repo — fine
  here (no sensitive data, not Play Store). To rotate to private signing, move
  these to GitHub Secrets and decode in CI.

## Architecture

Exercises come from a **catalog**; only the user's own data is in SQLite.

- **Base dataset (offline):** `assets/data/exercises.json` — the full
  [free-exercise-db](https://github.com/yuhonas/free-exercise-db) (~876
  exercises: name, muscles, equipment, level, instructions, images). Public
  domain (Unlicense).
- **Enrichment (remote, editable without rebuild):** `data/exercise_overrides.json`
  plus the full `assets/data/exercises.json`, both pulled over
  `raw.githubusercontent.com` and merged/replacing the bundled copies. Set the
  ref in `lib/data/remote_config.dart` (`RemoteConfig.dataRepoRef` →
  `overridesUrl`/`datasetUrl`) — switch to `main` after merging. **The repo must
  be public** for the phone to fetch it.
- **Sync is manual.** Nothing is fetched at launch — `ExerciseCatalog.load()`
  reads bundled assets + on-device caches only. **Settings → Sync now**
  (`GymProvider.syncRemoteData` → `ExerciseCatalog.syncRemote`) pulls fresh data
  and caches it; the bundled copies are the offline default.
- **Bodyweight flag:** each exercise in `assets/data/exercises.json` has a curated
  `bodyweight: true|false` (the `equipment` tag is unreliable). `CatalogExercise`
  reads it; `usesBodyweight` prefers the flag, falling back to
  `equipment == 'body only'`. Regenerate/adjust classification in that file (or
  patch per-exercise via the overrides `bodyweight` key).
- **Demo images:** streamed from free-exercise-db raw URLs and cached
  (`cached_network_image`). Requires the `INTERNET` permission, which is in
  `android/app/src/main/AndroidManifest.xml` (Flutter omits it from release by
  default — do not remove it).

### Key files

```
lib/
  main.dart, app.dart                 # entry + bottom-nav shell
  theme.dart                          # Material 3 theme (indigo seed)
  data/
    remote_config.dart                # image base URL + overrides URL/ref
    exercise_catalog.dart             # loads base+overrides+custom; query/filter
    muscle_taxonomy.dart              # muscle name -> body region / MuscleGroup
    database.dart                     # sqflite schema v2 (workouts/sets/custom)
    gym_repository.dart               # all DB access; resolves ids via catalog
  models/
    catalog_exercise.dart             # rich exercise (string id, muscles, images)
    muscle_group.dart                 # broad group enum (icon/colour/label)
    workout.dart, workout_exercise.dart, exercise_set.dart, aggregates.dart
  state/gym_provider.dart             # ChangeNotifier; owns catalog + repository
  screens/                            # home, history, exercises, exercise_detail,
                                      # exercise_picker, workout_detail, progress
  widgets/                            # exercise_demo (network), muscle_map
                                      # (CustomPainter), set_editor, common
data/exercise_overrides.json          # THE enrichment file (see data/README.md)
```

### Data model notes

- Exercises are identified by **string ids** (dataset id, or `custom_<micros>`).
- `workout_exercises` stores `exercise_id` plus a **snapshot** of name +
  muscle_group so history survives catalog changes; if an id vanishes the repo
  builds a `CatalogExercise.placeholder`.
- DB is **version 3**. `onUpgrade` from v1 still drops & recreates the training
  tables (the model changed fundamentally in v2); from v2→v3 it is **additive
  only** (`ALTER TABLE sets ADD COLUMN body_weight/created_at`, plus the new
  `profile` and `body_metrics` tables) so existing workout data is preserved.
  Prefer additive migrations going forward; bump the version if you change schema.
- Sets carry `created_at` (for rest timers) and an optional `body_weight`
  snapshot; for bodyweight exercises (`equipment == 'body only'`) volume/1RM use
  `effectiveWeight = weight + bodyWeight`. Bodyweight comes from the latest
  `body_metrics` entry (`GymProvider.currentBodyWeight`).
- `profile` (single row id=1) holds sex/birth year/height/activity/goal/target;
  health formulas live in `lib/utils/health.dart` (pure, unit-tested).
- Food macro search (`lib/data/food_repository.dart`) hits Open Food Facts
  (no API key) with a bundled `assets/data/foods_common.json` offline fallback.
- Custom exercises live in the `custom_exercises` table and are merged into the
  catalog on load.

### Precise muscles

`primaryMuscles`/`secondaryMuscles` may be **precise** (e.g. `lateral deltoid`,
`upper chest`, `triceps (long head)`). `lib/data/muscle_taxonomy.dart`
`baseRegion()` maps any name (broad or precise) to a body-map region by keyword;
the exact text is shown on the "muscles worked" chips. To add precise targeting
for an exercise, add/patch its entry in `data/exercise_overrides.json` (keyed by
dataset id) and push — no rebuild needed. Format is documented in
`data/README.md`.

## Conventions / gotchas

- Keep `flutter analyze` clean; match existing style (Material 3, `provider`).
- The Gradle wrapper jar + `gradlew` are **force-added** (Flutter gitignores
  them) so CI can build; `android/local.properties` stays ignored.
- Don't bundle the full image set (1,740 files) — images stream + cache.
- When adding runtime network calls, remember release needs `INTERNET`.
- Do not attempt `flutter build apk` / `flutter run` in the sandbox; validate
  with analyze/test and let CI build.
