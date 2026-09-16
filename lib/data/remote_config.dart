/// Endpoints for remotely-loaded data.
///
/// The enrichment file lives in the `mygym` GitHub repo and is fetched at
/// launch, so exercise detail (precise muscles, new exercises) can be updated
/// without rebuilding the app. After merging to `main`, change [dataRepoRef]
/// to `main`.
class RemoteConfig {
  /// Base URL for free-exercise-db demo images (relative image paths in the
  /// dataset are resolved against this).
  static const imageBase =
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/';

  /// Git ref (branch/tag) in the mygym repo that holds the enrichment file.
  static const dataRepoRef = 'claude/gym-tracker-android-app-gc9ngm';

  /// The enrichment / overrides file, pulled on a manual Sync.
  static const overridesUrl =
      'https://raw.githubusercontent.com/zeroonea/mygym/$dataRepoRef/data/exercise_overrides.json';

  /// The full exercise dataset (with the curated `bodyweight` flags), pulled on
  /// a manual Sync so classification edits reach the phone without a rebuild.
  static const datasetUrl =
      'https://raw.githubusercontent.com/zeroonea/mygym/$dataRepoRef/assets/data/exercises.json';
}
