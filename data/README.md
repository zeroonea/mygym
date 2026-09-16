# MyGym exercise enrichment data

`exercise_overrides.json` is merged on top of the bundled
[free-exercise-db](https://github.com/yuhonas/free-exercise-db) dataset. It lets
you refine or add exercise detail **without rebuilding the APK** — edit this
file, push, and pull it onto the phone via **Settings → Sync now**.

> **Sync is manual.** The app fetches nothing at launch. Both this overrides
> file and the full `assets/data/exercises.json` (with its `bodyweight` flags)
> are pulled over `raw.githubusercontent.com` only when you tap **Sync now**,
> then cached on the device (used offline until the next sync). The bundled
> copies are the default until you sync.

The app reads both from the ref set in `lib/data/remote_config.dart`
(`RemoteConfig.dataRepoRef`, used by `overridesUrl` and `datasetUrl`). Point that
at `main` once this branch is merged.

## Bodyweight classification

Each exercise in `assets/data/exercises.json` carries a curated
`"bodyweight": true|false` flag (the raw `equipment` tag is unreliable — dips and
muscle-ups are tagged `other`). When `true`, logged sets count the lifter's
bodyweight toward volume/1RM (`effectiveWeight = added load + bodyweight`). You
can also flip it per-exercise from this overrides file via the `bodyweight` key
(see below); the flag wins over the `equipment` heuristic.

## Format

```jsonc
{
  "version": 1,
  "updated": "YYYY-MM-DD",
  "overrides": {
    "<free-exercise-db id>": {
      "primaryMuscles":   ["lateral deltoid"],
      "secondaryMuscles": ["anterior deltoid", "upper trapezius"],
      // any of these may also be overridden:
      "name": "...", "category": "...", "equipment": "...", "bodyweight": true,
      "level": "...", "instructions": ["..."], "images": ["url-or-relative"]
    }
  },
  "additions": [
    { "id": "my_custom_move", "name": "My Move", "primaryMuscles": ["chest"],
      "instructions": ["..."], "images": ["https://.../0.jpg"] }
  ]
}
```

- **overrides** patch an existing exercise; only the keys you include change.
  The key is the dataset `id` (see `assets/data/exercises.json`, e.g.
  `Side_Lateral_Raise`).
- **additions** are whole new exercises (unique `id`). `images` may be absolute
  URLs or paths relative to the free-exercise-db image base.

## Precise muscles

`primaryMuscles` / `secondaryMuscles` may use **precise** names instead of the
dataset's broad ones. The app maps them to body-map regions by keyword, so any
of these resolve correctly:

| You write | Highlights |
|---|---|
| `lateral deltoid`, `anterior deltoid`, `rear deltoid` | shoulders |
| `upper chest`, `mid chest`, `lower chest` | chest |
| `triceps (long head)`, `biceps`, `brachialis` | arms |
| `upper trapezius`, `rhomboids`, `lats`, `lower back` | back |
| `quadriceps`, `hamstrings`, `glutes`, `calves (soleus)` | legs |
| `abdominals`, `obliques`, `hip flexors` | core |

The exact text you write is what shows on the exercise's "muscles worked" chips,
so `lateral deltoid` displays as **Lateral Deltoid** while still lighting up the
shoulder on the map.
