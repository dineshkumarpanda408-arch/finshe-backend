import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'screens/animated_splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'services/notification_service.dart';
import 'theme/finshe_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.init();
  runApp(const FinsheApp());
}

class FinsheApp extends StatelessWidget {
  const FinsheApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: MaterialApp(
        title: 'Finshe',
        debugShowCheckedModeBanner: false,
        theme: buildFinsheTheme(),
        themeMode: ThemeMode.dark,
        home: const _FinsheBootstrap(),
      ),
    );
  }
}

class _FinsheBootstrap extends StatefulWidget {
  const _FinsheBootstrap();

  @override
  State<_FinsheBootstrap> createState() => _FinsheBootstrapState();
}

class _FinsheBootstrapState extends State<_FinsheBootstrap> {
  bool _splashComplete = false;

  @override
  Widget build(BuildContext context) {
    if (!_splashComplete) {
      return AnimatedSplashScreen(
        onFinished: () {
          if (mounted) setState(() => _splashComplete = true);
        },
      );
    }
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        if (app.currentUser != null) {
          return const MainShell();
        }
        return const LoginScreen();
      },
    );
  }
}
