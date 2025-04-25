import 'package:chat_web/controller/router_provider.dart';
import 'package:chat_web/controller/theme_controller.dart';
import 'package:chat_web/core/const/theme_const.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Load theme preferences when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(themeProvider.notifier).loadTheme();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      theme: AppTheme.light(fontFamily: 'Inter'),
      darkTheme: AppTheme.dark(fontFamily: 'Inter'),
      themeMode: themeState.themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false, // Add this for cleaner debug mode
    );
  }
}