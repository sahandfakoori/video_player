import 'package:flutter/material.dart';
import 'package:flutter_application_1/presentation/video_player_screen/video_player_screen.dart';
import 'package:flutter_application_1/presentation/video_player_screen/widgets/favorites_manager.dart';
import 'package:flutter_application_1/widgets/videoListTile.dart';

class favoritesScreen extends StatefulWidget {
  const favoritesScreen({super.key});

  @override
  State<favoritesScreen> createState() => _favoritesScreenState();
}

class _favoritesScreenState extends State<favoritesScreen> {
  @override
  void initState() {
    super.initState();
    FavoritesManager().loadFavorites().then((_) {
      setState(() {});
    });
  }

  Widget build(BuildContext context) {
    final favorites = FavoritesManager().favorites;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My favorite videos",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
        ),
      ),
      body: favorites.isEmpty
          ? Center(
              child: Image.asset(
                'assets/images/download.png',
                width: 450,
                height: 450,
              ),
            )
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final video = favorites[index];
                return VideoListTile(
                  video: video,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoPlayerScreen(
                          video: video,
                          videos: favorites,
                          initialIndex: index,
                          isInFavoritesScreen: true,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
