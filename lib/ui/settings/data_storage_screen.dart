import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../state/scopes.dart';
import '../../telegram/telegram_store.dart';
import '../components/glass.dart';
import '../components/ios_ui.dart';
import '../components/sheets.dart';

class DataStorageScreen extends StatefulWidget {
  const DataStorageScreen({super.key});

  @override
  State<DataStorageScreen> createState() => _DataStorageScreenState();
}

class _DataStorageScreenState extends State<DataStorageScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) TelegramScope.read(context).loadStorage();
    });
  }

  Future<void> _clear() async {
    final bool ok = await showGlassConfirm(
      context,
      title: 'Clear cache?',
      message: 'Downloaded photos and files are removed from this device. '
          'Messages stay on Telegram\'s servers and can be downloaded again.',
      confirmLabel: 'Clear',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    await TelegramScope.read(context).clearCache();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final TelegramStore store = TelegramScope.of(context);
    return Scaffold(
      backgroundColor: colors.groupedBackground,
      appBar: AppBar(
        backgroundColor: colors.groupedBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Data and storage'),
        actions: <Widget>[
          IconButton(
            onPressed: store.loadStorage,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
        children: <Widget>[
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: <Widget>[
                Icon(Icons.storage_outlined, size: 34, color: colors.accent),
                const SizedBox(height: 10),
                Text(
                  store.storageSize > 0
                      ? fileSizeLabel(store.storageSize)
                      : 'No cached media',
                  style: AppText.headline.copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  '${store.storageCount} files in the local TDLib cache',
                  style: AppText.subhead.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SettingsGroup(
            children: <Widget>[
              SettingsRow(
                label: 'Clear cache',
                subtitle: 'Keep messages, remove downloaded files',
                icon: Icons.cleaning_services_outlined,
                iconColor: colors.danger,
                onTap: _busy ? null : _clear,
                trailing: _busy
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'TDLib keeps a local database and a media cache in the app '
            'sandbox. Clearing the cache never deletes messages from Telegram.',
            style: AppText.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
