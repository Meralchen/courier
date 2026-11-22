import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../state/scopes.dart';
import '../../telegram/telegram_store.dart';
import '../components/glass.dart';
import '../components/ios_ui.dart';
import 'auth_scaffold.dart';

class CodeScreen extends StatefulWidget {
  const CodeScreen({super.key});

  @override
  State<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends State<CodeScreen> {
  final TextEditingController _code = TextEditingController();
  Timer? _timer;
  int _seconds = 30;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) return;
      if (_seconds <= 1) {
        timer.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await TelegramScope.read(context).submitCode(_code.text);
  }

  @override
  Widget build(BuildContext context) {
    final TelegramStore store = TelegramScope.of(context);
    final AppColors colors = AppColors.of(context);
    return AuthScaffold(
      title: 'Enter the code',
      subtitle: 'We sent a login code to your Telegram app or by SMS.',
      showBrand: false,
      footer: TextButton(
        onPressed: _seconds == 0
            ? () {
                _startTimer();
                store.resendCode();
              }
            : null,
        child: Text(
          _seconds == 0 ? 'Resend code' : 'Resend code in ${_seconds}s',
          style: AppText.subhead.copyWith(
            color: _seconds == 0 ? colors.accent : colors.textSecondary,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GlassField(
            controller: _code,
            hint: 'Login code',
            icon: Icons.lock_clock_outlined,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofocus: true,
            onSubmitted: (_) => _submit(),
            suffix: IconButton(
              onPressed: _submit,
              icon: Icon(Icons.arrow_forward, color: colors.accent, size: 20),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '5 digits, sent by Telegram. Nothing is stored on a Courier server.',
            style: AppText.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 14),
          GlassPrimaryButton(
            label: 'Sign in',
            busy: store.auth.busy,
            onTap: _submit,
          ),
          ErrorLine(store.auth.error),
          const SizedBox(height: 2),
          TextButton(
            onPressed: () => store.logout(),
            child: Text(
              'Use a different number',
              style: AppText.subhead.copyWith(color: colors.accent),
            ),
          ),
        ],
      ),
    );
  }
}
