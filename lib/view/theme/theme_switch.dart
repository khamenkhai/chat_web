import 'package:chat_web/controller/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeSwitch extends ConsumerWidget {
  const ThemeSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final isDark = themeState.isDarkMode;

    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return RotationTransition(
            turns: animation,
            child: ScaleTransition(scale: animation, child: child),
          );
        },
        child: isDark
            ? const Icon(Icons.nightlight_round, key: Key('moon'))
            : const Icon(Icons.wb_sunny, key: Key('sun')),
      ),
      onPressed: () {
        ref.read(themeProvider.notifier).toggleTheme(!isDark);
      },
    );
  }
}

class SunMoonThemeSelector extends ConsumerWidget {
  const SunMoonThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<ThemeMode>(
      icon: const Icon(Icons.brightness_4_outlined),
      onSelected: (mode) {
        ref.read(themeProvider.notifier).setThemeMode(mode);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: ThemeMode.system,
          child: Row(
            children: const [
              Icon(Icons.settings_suggest_outlined),
              SizedBox(width: 8),
              Text('System Theme'),
            ],
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.light,
          child: Row(
            children: const [
              Icon(Icons.wb_sunny, color: Colors.amber),
              SizedBox(width: 8),
              Text('Light Mode'),
            ],
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.dark,
          child: Row(
            children: const [
              Icon(Icons.nightlight_round, color: Colors.indigo),
              SizedBox(width: 8),
              Text('Dark Mode'),
            ],
          ),
        ),
      ],
    );
  }
}