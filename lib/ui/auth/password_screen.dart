import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../state/scopes.dart';
import '../../telegram/telegram_store.dart';
import '../components/glass.dart';
import '../components/ios_ui.dart';
import 'auth_scaffold.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _password = TextEditingController();
  bool _visible = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await TelegramScope.read(context).submitPassword(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    final TelegramStore store = TelegramScope.of(context);
    final AppColors colors = AppColors.of(context);
    final String? hint = store.auth.passwordHint;
    return AuthScaffold(
      title: 'Two-step verification',
      subtitle: 'Your account is protected by a password you set in Telegram.',
      showBrand: false,
      footer: Text(
        'Forgot it? Telegram can reset the password after a recovery period.',
        textAlign: TextAlign.center,
        style: AppText.caption.copyWith(color: colors.textSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (hint != null && hint.isNotEmpty) ...<Widget>[
            Text(
              'Hint: $hint',
              style: AppText.footnote.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 10),
          ],
          GlassField(
            controller: _password,
            hint: 'Password',
            icon: Icons.password,
            obscure: !_visible,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            suffix: IconButton(
              onPressed: () => setState(() => _visible = !_visible),
              icon: Icon(
                _visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: colors.textSecondary,
                size: 19,
              ),
            ),
          ),
          const SizedBox(height: 14),
          GlassPrimaryButton(
            label: 'Unlock',
            busy: store.auth.busy,
            onTap: _submit,
          ),
          ErrorLine(store.auth.error),
        ],
      ),
    );
  }
}
