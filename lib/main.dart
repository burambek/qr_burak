import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'services/storage_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(storage),
      child: const SbApp(),
    ),
  );
}

class SbApp extends StatelessWidget {
  const SbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SB',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const RootNavigator(),
    );
  }
}

class RootNavigator extends StatelessWidget {
  const RootNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AppProvider>().isLoggedIn;
    return isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
}