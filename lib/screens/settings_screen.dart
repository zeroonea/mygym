import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/exercise_catalog.dart';
import '../data/remote_config.dart';
import '../state/gym_provider.dart';
import '../utils/format.dart';

/// App settings. Currently hosts the manual "Sync exercise data" action —
/// nothing is fetched automatically at launch, so this is how fresh exercise
/// data (including the curated bodyweight flags) reaches the phone.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _sync(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await context.read<GymProvider>().syncRemoteData();
    messenger.showSnackBar(SnackBar(content: Text(result.message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        top: false,
        child: Consumer<GymProvider>(
          builder: (context, provider, _) {
            final synced = provider.dataSource == DataSource.synced;
            final at = provider.lastSyncedAt;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Text('Exercise data',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            synced ? Icons.cloud_done_outlined : Icons.sd_card,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  synced
                                      ? 'Synced from GitHub'
                                      : 'Bundled with the app',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  synced && at != null
                                      ? 'Last synced ${relativeDay(at)} · ${formatClock(at)}'
                                      : 'Tap sync to pull the latest data',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Pulls the latest exercise dataset — including the '
                        'bodyweight classification used for volume — and any '
                        'enrichment overrides from the mygym repo. Runs only '
                        'when you tap it; nothing is fetched at launch.',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              provider.syncing ? null : () => _sync(context),
                          icon: provider.syncing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.sync),
                          label: Text(
                              provider.syncing ? 'Syncing…' : 'Sync now'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Source: ${RemoteConfig.dataRepoRef}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            );
          },
        ),
      ),
    );
  }
}
