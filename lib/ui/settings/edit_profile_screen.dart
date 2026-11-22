import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../state/scopes.dart';
import '../../telegram/models.dart';
import '../../telegram/telegram_store.dart';
import '../components/avatar.dart';
import '../components/glass.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _first = TextEditingController();
  final TextEditingController _last = TextEditingController();
  final TextEditingController _bio = TextEditingController();
  final TextEditingController _username = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final Profile? me = TelegramScope.of(context).me;
    if (me != null) {
      _first.text = me.firstName;
      _last.text = me.lastName;
      _bio.text = me.bio;
      _username.text = me.username;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _bio.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final TelegramStore store = TelegramScope.read(context);
    setState(() => _saving = true);
    await store.updateProfile(
      firstName: _first.text,
      lastName: _last.text,
      bio: _bio.text,
      username: _username.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    final String? error = store.takeError();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final Profile? me = TelegramScope.of(context).me;
    return Scaffold(
      backgroundColor: colors.groupedBackground,
      appBar: AppBar(
        backgroundColor: colors.groupedBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Edit profile'),
        actions: <Widget>[
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: <Widget>[
          Center(
            child: Avatar(
              title: me?.name ?? 'Courier user',
              seed: me?.id ?? 1,
              size: 88,
              photoFileId: me?.photoFileId ?? 0,
              photoPath: me?.photoPath ?? '',
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Profile photo is managed in Telegram',
              style: AppText.caption.copyWith(color: colors.textSecondary),
            ),
          ),
          const SizedBox(height: 22),
          Text('Name', style: AppText.caption.copyWith(color: colors.textSecondary)),
          const SizedBox(height: 6),
          GlassField(
            controller: _first,
            hint: 'First name',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 8),
          GlassField(
            controller: _last,
            hint: 'Last name',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 18),
          Text('Username', style: AppText.caption.copyWith(color: colors.textSecondary)),
          const SizedBox(height: 6),
          GlassField(
            controller: _username,
            hint: 'username',
            icon: Icons.alternate_email,
          ),
          const SizedBox(height: 18),
          Text('Bio', style: AppText.caption.copyWith(color: colors.textSecondary)),
          const SizedBox(height: 6),
          GlassField(
            controller: _bio,
            hint: 'A few words about you',
            maxLines: 3,
          ),
          const SizedBox(height: 18),
          GlassCard(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: <Widget>[
                Icon(Icons.phone_outlined, size: 17, color: colors.textSecondary),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    me?.phone.isNotEmpty == true ? me!.phone : 'No phone number',
                    style: AppText.subhead.copyWith(color: colors.textPrimary),
                  ),
                ),
                Text(
                  'Change in Telegram',
                  style: AppText.caption.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Name, username and bio are sent to Telegram through TDLib and '
            'apply to every device on your account.',
            style: AppText.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
