import 'package:flutter/material.dart';
import 'package:flutter_application_1/presentation/splash_screen/splash_screen.dart';
import 'package:flutter_application_1/presentation/video_player_screen/widgets/favorites_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FavoritesManager().loadFavorites();

  runApp(const MyApp());
}

ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light().copyWith(
            brightness: Brightness.light,
            appBarTheme: AppBarTheme(
              backgroundColor: Color(0xFF0D47A1),
              foregroundColor: Colors.white,
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: Color(0xFF14141A),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E28),
              foregroundColor: Colors.white,
            ),
          ),
          themeMode: currentMode,
          home: const SplashPage(),
        );
      },
    );
  }
}
