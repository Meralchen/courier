import 'package:material_ui/material_ui.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../state/scopes.dart';
import '../../telegram/models.dart';
import '../../telegram/telegram_store.dart';
import '../components/glass.dart';
import '../components/ios_ui.dart';
import 'auth_scaffold.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final TextEditingController _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await TelegramScope.read(context).submitPhone(_phone.text);
  }

  @override
  Widget build(BuildContext context) {
    final TelegramStore store = TelegramScope.of(context);
    final AppColors colors = AppColors.of(context);
    final bool busy = store.auth.busy || store.auth.stage == AuthStage.starting;
    return AuthScaffold(
      title: 'Your phone number',
      subtitle: 'Sign in to Telegram with the number registered to your account.',
      footer: Text(
        'Courier talks to Telegram directly through TDLib. Your messages are '
        'encrypted in transit and never pass through a Courier server.',
        textAlign: TextAlign.center,
        style: AppText.caption.copyWith(color: colors.textSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GlassField(
            controller: _phone,
            hint: '+49 170 1234567',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.go,
            autofocus: true,
            onSubmitted: (_) => _submit(),
            maxLines: 1,
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Icon(Icons.lock_outline, size: 13, color: colors.textSecondary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Include your country code. Telegram may send the code in-app.',
                  style: AppText.caption.copyWith(color: colors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GlassPrimaryButton(
            label: 'Continue',
            busy: busy,
            onTap: () {
              Haptics.medium();
              _submit();
            },
          ),
          ErrorLine(store.auth.error),
          if (store.connection != 'Connected') ...<Widget>[
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Icon(Icons.wifi_off, size: 13, color: colors.textSecondary),
                const SizedBox(width: 5),
                Text(
                  store.connection,
                  style: AppText.caption.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
