import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme.dart';
import 'state/app_settings.dart';
import 'state/scopes.dart';
import 'telegram/models.dart';
import 'telegram/telegram_store.dart';
import 'ui/auth/auth_flow.dart';
import 'ui/shell.dart';
import 'ui/splash_screen.dart';

class CourierApp extends StatefulWidget {
  const CourierApp({super.key});

  @override
  State<CourierApp> createState() => _CourierAppState();
}

class _CourierAppState extends State<CourierApp> {
  final TelegramStore _store = TelegramStore();
  final AppSettings _settings = AppSettings();

  @override
  void initState() {
    super.initState();
    _settings.load();
    _store.boot();
  }

  @override
  void dispose() {
    _store.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      settings: _settings,
      child: TelegramScope(
        store: _store,
        child: AnimatedBuilder(
          animation: _settings,
          builder: (BuildContext context, Widget? child) {
            return MaterialApp(
              title: 'Courier',
              debugShowCheckedModeBanner: false,
              theme: buildTheme(AppColors.light),
              darkTheme: buildTheme(AppColors.darkMode),
              themeMode: _settings.themeMode,
              home: child,
              builder: (BuildContext context, Widget? page) {
                final AppColors colors = AppColors.of(context);
                return AnnotatedRegion<SystemUiOverlayStyle>(
                  value: colors.dark
                      ? SystemUiOverlayStyle.light
                      : SystemUiOverlayStyle.dark,
                  child: page ?? const SizedBox.shrink(),
                );
              },
            );
          },
          child: const RootGate(),
        ),
      ),
    );
  }
}

/// Chooses the surface for the current TDLib authorisation stage.
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final TelegramStore store = TelegramScope.of(context);
    if (store.signedIn) return const MainShell();

    final AuthState auth = store.auth;
    return switch (auth.stage) {
      AuthStage.waitCode => const CodeScreen(),
      AuthStage.waitPassword => const PasswordScreen(),
      AuthStage.starting => const SplashScreen(),
      AuthStage.loggingOut => const SplashScreen(signingOut: true),
      AuthStage.error => _EngineError(message: auth.error),
      _ => const PhoneScreen(),
    };
  }
}

class _EngineError extends StatelessWidget {
  const _EngineError({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final TelegramStore store = TelegramScope.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Telegram could not start',
                style: AppText.headline,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message ?? 'TDLib did not initialize on this device.',
                style: AppText.subhead.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => store.retryEngine(),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
