import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:big_frames/core/theme/app_theme.dart';
import 'package:big_frames/presentation/router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Here we would configure window size/settings using desktop_window or window_manager
  // if those packages were added, but we'll stick to standard flutter sizes for now.
  
  runApp(
    const ProviderScope(
      child: BigFramesApp(),
    ),
  );
}

class BigFramesApp extends ConsumerWidget {
  const BigFramesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Big Frames',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Or read from settings provider
      initialRoute: AppRouter.home,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
