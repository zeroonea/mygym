# MyGym exercise enrichment data

`exercise_overrides.json` is loaded by the app at launch (over
`raw.githubusercontent.com`) and merged on top of the bundled
[free-exercise-db](https://github.com/yuhonas/free-exercise-db) dataset. It lets
you refine or add exercise detail **without rebuilding the APK** — edit this
file, push, and the app picks it up on next launch (it also caches the last
successful copy for offline use).

The app reads it from the ref set in `lib/data/remote_config.dart`
(`RemoteConfig.dataRepoRef`). Point that at `main` once this branch is merged.

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
      "name": "...", "category": "...", "equipment": "...",
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
