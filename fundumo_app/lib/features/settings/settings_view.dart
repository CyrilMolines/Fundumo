import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../application/fundumo_controller.dart';
import '../../application/notification_prefs_controller.dart';
import '../../application/theme_controller.dart';
import '../../data/fundumo_repository.dart';
import '../../domain/models/models.dart';
import '../../services/notification_prefs_service.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  String? _status;
  bool _isBusy = false;
  FileStat? _lastBackupStat;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _incomeController;
  final _profileFormKey = GlobalKey<FormState>();
  bool _profileInitialized = false;
  String _selectedCurrency = 'USD';

  static const List<String> _currencies = [
    'USD',
    'EUR',
    'GBP',
    'CAD',
    'AUD',
    'JPY',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _incomeController = TextEditingController();
    _refreshBackupInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = ref.read(fundumoControllerProvider).valueOrNull;
      if (data != null && !_profileInitialized) {
        _initializeProfileFields(data);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  Future<void> _refreshBackupInfo() async {
    try {
      final file = await _resolveBackupFile();
      if (!await file.exists()) {
        setState(() {
          _lastBackupStat = null;
        });
        return;
      }
      final stat = await file.stat();
      setState(() {
        _lastBackupStat = stat;
      });
    } catch (_) {
      setState(() {
        _lastBackupStat = null;
      });
    }
  }

  void _initializeProfileFields(FundumoData data) {
    setState(() {
      _profileInitialized = true;
      _selectedCurrency = data.user.currencyCode;
    });
    _nameController.text = data.user.name;
    _emailController.text = data.user.notificationEmail;
    _incomeController.text =
        data.user.monthlyTakeHome.toStringAsFixed(0);
  }


  Future<void> _runOperation(Future<void> Function() action) async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _status = null;
    });
    try {
      await action();
    } catch (error) {
      setState(() {
        _status = 'Error: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  void _saveProfile(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    if (!_profileFormKey.currentState!.validate()) {
      return;
    }
    final income = double.tryParse(
          _incomeController.text.replaceAll(',', ''),
        ) ??
        0;
    _runOperation(() async {
      ref.read(fundumoControllerProvider.notifier).updateUserProfile(
            name: _nameController.text.trim(),
            notificationEmail: _emailController.text.trim(),
            monthlyTakeHome: income,
            currencyCode: _selectedCurrency,
          );
      if (!mounted) return;
      setState(() {
        _status = 'Profile updated';
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    });
  }

  void _updateNotificationPrefs(
    BuildContext context,
    NotificationPreferences prefs,
  ) {
    ref.read(notificationPrefsControllerProvider.notifier).setPrefs(prefs);
    setState(() {
      _status = 'Notification preferences updated';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification preferences saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controllerState = ref.watch(fundumoControllerProvider);
    final themeModeState = ref.watch(themeControllerProvider);
    final currentThemeMode =
        themeModeState.valueOrNull ?? ThemeMode.system;
    final notificationState = ref.watch(notificationPrefsControllerProvider);
    final notificationPrefs = notificationState.valueOrNull ??
        const NotificationPreferences(
          budgetAlerts: true,
          subscriptionAlerts: true,
          warrantyAlerts: true,
        );
    if (controllerState.hasValue && !_profileInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final data = controllerState.value;
        if (data != null && !_profileInitialized) {
          _initializeProfileFields(data);
        }
      });
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        Text(
          'Profile',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Update the name, currency, and pay-cycle amounts used across insights.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        if (controllerState.isLoading && !_profileInitialized)
          const Center(child: CircularProgressIndicator())
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _profileFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Notification email',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _incomeController,
                            decoration: const InputDecoration(
                              labelText: 'Monthly take-home',
                              prefixText: '\$',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              final parsed =
                                  double.tryParse(value?.replaceAll(',', '') ?? '');
                              if (parsed == null || parsed <= 0) {
                                return 'Enter a positive amount';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownMenu<String>(
                            initialSelection: _selectedCurrency,
                            label: const Text('Currency'),
                            dropdownMenuEntries: _currencies
                                .map(
                                  (currency) => DropdownMenuEntry(
                                    value: currency,
                                    label: currency,
                                  ),
                                )
                                .toList(),
                            onSelected: (value) {
                              if (value != null) {
                                setState(() => _selectedCurrency = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _isBusy ? null : () => _saveProfile(context),
                        icon: const Icon(Icons.save),
                        label: const Text('Save profile'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
        Text(
          'Appearance',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Adjust the theme mode for this device.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.phone_android),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: {currentThemeMode},
              onSelectionChanged: (selection) {
                final mode = selection.first;
                ref
                    .read(themeControllerProvider.notifier)
                    .setTheme(mode);
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Notifications',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Choose which alerts Fundumo should surface on this device.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        if (notificationState.isLoading && notificationState.valueOrNull == null)
          const Center(child: CircularProgressIndicator())
        else
          Card(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  title: const Text('Envelope budget alerts'),
                  subtitle:
                      const Text('Warn me when envelopes exceed their allocation'),
                  value: notificationPrefs.budgetAlerts,
                  onChanged: (value) {
                    _updateNotificationPrefs(
                      context,
                      notificationPrefs.copyWith(budgetAlerts: value),
                    );
                  },
                ),
                SwitchListTile.adaptive(
                  title: const Text('Subscription renewals'),
                  subtitle:
                      const Text('Remind me when subscriptions renew soon'),
                  value: notificationPrefs.subscriptionAlerts,
                  onChanged: (value) {
                    _updateNotificationPrefs(
                      context,
                      notificationPrefs.copyWith(subscriptionAlerts: value),
                    );
                  },
                ),
                SwitchListTile.adaptive(
                  title: const Text('Warranty & receipt alerts'),
                  subtitle: const Text('Warn me before warranties expire'),
                  value: notificationPrefs.warrantyAlerts,
                  onChanged: (value) {
                    _updateNotificationPrefs(
                      context,
                      notificationPrefs.copyWith(warrantyAlerts: value),
                    );
                  },
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        Text(
          'Data & backups',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Fundumo stores your working set locally. Use the controls below to '
          'export an encrypted JSON snapshot to your documents folder or '
          'restore from the most recent backup file.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _isBusy
              ? null
              : () {
                  final messenger = ScaffoldMessenger.of(context);
                  _runOperation(() async {
                    final file =
                        await ref.read(backupServiceProvider).exportBackup();
                    if (!mounted) return;
                    setState(() {
                      _status = 'Backup saved to ${file.path}';
                    });
                    await _refreshBackupInfo();
                    messenger.showSnackBar(
                      SnackBar(content: Text('Backup exported: ${file.path}')),
                    );
                  });
                },
          icon: const Icon(Icons.cloud_upload_outlined),
          label: const Text('Export backup'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isBusy
              ? null
              : () {
                  final messenger = ScaffoldMessenger.of(context);
                  _runOperation(() async {
                    final file = await _resolveBackupFile();
                    final data =
                        await ref.read(backupServiceProvider).importBackup();
                    await ref
                        .read(fundumoControllerProvider.notifier)
                        .replaceData(data);
                    if (!mounted) return;
                    setState(() {
                      _status = 'Backup restored from ${file.path}';
                      _profileInitialized = false;
                    });
                    await _refreshBackupInfo();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Backup restored')),
                    );
                  });
                },
          icon: const Icon(Icons.restore),
          label: const Text('Restore latest backup'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: (_isBusy || _lastBackupStat == null)
              ? null
              : () async {
                  final file = await _resolveBackupFile();
                  await Share.shareXFiles([XFile(file.path)],
                      text: 'Fundumo backup');
                },
          icon: const Icon(Icons.ios_share),
          label: const Text('Share backup file'),
        ),
        const SizedBox(height: 24),
        _BackupMetadata(stat: _lastBackupStat),
        const SizedBox(height: 24),
        Text(
          'Tips',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const _TipTile(
          title: 'Off-site safety',
          body:
              'Copy the exported fundumo_backup.json file to encrypted cloud storage '
              'or removable media to prevent device loss.',
        ),
        const _TipTile(
          title: 'Automate reminders',
          body:
              'Schedule a calendar reminder to export backups weekly until the cloud sync '
              'service is rolled out.',
        ),
        const SizedBox(height: 24),
        Text(
          'Danger zone',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: theme.colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delete local data',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Resets every envelope, transaction, and configuration back to '
                  'the sample data set. Export a backup first if you plan to restore later.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Delete & reload sample data'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.onErrorContainer,
                    foregroundColor: theme.colorScheme.errorContainer,
                  ),
                  onPressed: _isBusy
                      ? null
                      : () {
                          final messenger = ScaffoldMessenger.of(context);
                          _runOperation(() async {
                            await ref
                                .read(fundumoControllerProvider.notifier)
                                .resetToSeed();
                            if (!mounted) return;
                            setState(() {
                              _status = 'Local data cleared';
                              _profileInitialized = false;
                            });
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Local data reset complete'),
                              ),
                            );
                          });
                        },
                ),
              ],
            ),
          ),
        ),
        if (_status != null) ...[
          const SizedBox(height: 24),
          Text(
            _status!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.tertiary,
            ),
          ),
        ],
      ],
    );
  }

  Future<File> _resolveBackupFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/fundumo_backup.json');
  }
}

class _TipTile extends StatelessWidget {
  const _TipTile({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(body),
          ],
        ),
      ),
    );
  }
}

class _BackupMetadata extends StatelessWidget {
  const _BackupMetadata({this.stat});

  final FileStat? stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.history),
        title: Text(
          stat == null
              ? 'No backup found'
              : 'Last backup: ${stat!.modified}',
        ),
        subtitle: stat == null
            ? const Text('Export a backup to create fundumo_backup.json')
            : Text(
                'Size: ${(stat!.size / 1024).toStringAsFixed(1)} KB',
                style: theme.textTheme.bodySmall,
              ),
      ),
    );
  }
}

