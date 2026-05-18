import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/domain/repository/repository.dart';
import 'package:flutter_application_1/domain/repository/repository_impl.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/presentation/favarite_screen/favorit_screen.dart';
import 'package:flutter_application_1/presentation/video_list_screen/video_list_screen.dart';
import 'package:flutter_application_1/presentation/video_player_screen/video_player_screen.dart';
import 'package:flutter_application_1/widgets/icon_button_widget.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_application_1/presentation/video_list_screen/widgets/delete.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:flutter_application_1/data/model/video_model.dart';

class FolderListScreen extends StatefulWidget {
  final Repository _repository = RepositoryImpl();
  FolderListScreen({super.key});

  @override
  State<FolderListScreen> createState() => _FolderListScreenState();
}

class _FolderListScreenState extends State<FolderListScreen> {
  Map<String, List<File>> folderVideos = {};
  bool islist = false;

  @override
  void initState() {
    super.initState();
    _scanFoldersForVideos();
  }

  Future<List<Directory>> _getStorageDirs() async {
    final List<Directory> dirs = [];
    dirs.add(Directory('/storage/emulated/0'));
    try {
      final storageRoot = Directory('/storage');
      if (await storageRoot.exists()) {
        final subDirs = storageRoot.listSync().whereType<Directory>().where((
          item,
        ) {
          final name = p.basename(item.path).toLowerCase();
          return name != 'emulated' && name != 'self';
        }).toList();

        dirs.addAll(subDirs);
      }
    } catch (e) {}
    try {
      final mediaRoot = Directory('/mnt/media_rw');
      if (await mediaRoot.exists()) {
        final subDirs = mediaRoot.listSync().whereType<Directory>().toList();
        dirs.addAll(subDirs);
      }
    } catch (e) {}
    final sdCardDir = Directory('/storage/5EA8-8727');
    if (await sdCardDir.exists()) {
      dirs.add(sdCardDir);
    }
    return dirs;
  }

  Future<void> _scanFoldersForVideos() async {
    final status = await Permission.manageExternalStorage.request();
    if (!status.isGranted) return;

    final rootDirs = await _getStorageDirs();
    Map<String, List<File>> videosByFolder = {};
    List<String> deletePaths = await getDeleteVideos();

    for (Directory root in rootDirs) {
      if (!await root.exists()) continue;
      await widget._repository.scanDirectoryRecursive(
        root,
        videosByFolder,
        deletePaths,
      );
    }

    setState(() {
      folderVideos = videosByFolder;
    });
  }

  Future<String?> getCachedThumbnailPath(File videoFile) async {
    final cacheDir = await getTemporaryDirectory();
    final hashedName = sha1.convert(utf8.encode(videoFile.path)).toString();
    final thumbPath = '${cacheDir.path}/$hashedName.jpg';
    final thumbFile = File(thumbPath);

    if (await thumbFile.exists() && await thumbFile.length() > 0) {
      return thumbPath;
    }

    final generatedPath = await VideoThumbnail.thumbnailFile(
      video: videoFile.path,
      thumbnailPath: thumbPath,
      imageFormat: ImageFormat.JPEG,
      maxHeight: 300,
      maxWidth: 300,
      quality: 75,
    );

    return generatedPath;
  }

  void _showStreamDialog() {
    TextEditingController urlController = TextEditingController();
    //کنترلر تکست فیلد که لینکو نگهداره
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Please enter your stream link",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: urlController,
            decoration: const InputDecoration(
              hintText: "http://example.com/stream.m3u8",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final url = urlController.text.trim();

                Navigator.pop(context);
                final video = VideoModel(path: url, name: url, file: File(""));

                if (url.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoPlayerScreen(
                        video: video,
                        videos: [video],
                        initialIndex: 0,
                      ),
                    ),
                  );
                }
              },
              child: const Text("Play"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<File> allVideos = folderVideos.values.expand((v) => v).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: const Text(
          'My Folders',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButtonWidget(
            icon: themeNotifier.value == ThemeMode.light
                ? Icons.dark_mode
                : Icons.light_mode,
            color: Colors.white,
            onPressed: () {
              themeNotifier.value = themeNotifier.value == ThemeMode.light
                  ? ThemeMode.dark
                  : ThemeMode.light;
            },
          ),

          IconButtonWidget(
            icon: FontAwesomeIcons.heart,
            size: 20,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const favoritesScreen()),
              );
            },
          ),

          IconButtonWidget(
            icon: islist ? Icons.format_list_bulleted_rounded : Icons.grid_view,
            onPressed: () {
              setState(() {
                islist = !islist;
              });
            },
          ),

          PopupMenuButton<String>(
            icon: const Icon(
              FontAwesomeIcons.arrowDownAZ,
              color: Colors.white,
              size: 18,
            ),
            onSelected: (value) {
              setState(() {
                if (value == 'name') {
                  folderVideos = Map.fromEntries(
                    folderVideos.entries.toList()
                      ..sort((a, b) => a.key.compareTo(b.key)),
                  );
                } else if (value == 'count') {
                  folderVideos = Map.fromEntries(
                    folderVideos.entries.toList()..sort(
                      (a, b) => b.value.length.compareTo(a.value.length),
                    ),
                  );
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'name', child: Text("sort by name")),
              const PopupMenuItem(
                value: 'count',
                child: Text("Sort by Video Count"),
              ),
            ],
          ),
        ],
      ),
      body: folderVideos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : islist
          ? GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 16 / 9,
              ),
              itemCount: allVideos.length,
              itemBuilder: (context, index) {
                final videoFile = allVideos[index];
                return FutureBuilder<String?>(
                  future: getCachedThumbnailPath(videoFile),
                  builder: (context, snapshot) {
                    final thumbPath = snapshot.data;
                    return GestureDetector(
                      onTap: () {
                        final videoModels = allVideos.map((file) {
                          return VideoModel(
                            path: file.path,
                            name: file.path.split('/').last,
                            file: file,
                            isFavorite: false,
                          );
                        }).toList();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VideoPlayerScreen(
                              video: videoModels[index],
                              videos: videoModels,
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black12,
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: thumbPath != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(thumbPath),
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(
                                videoFile.path.split('/').last,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            )
          : ListView(
              children: folderVideos.keys.map((folderName) {
                final isDarkMode =
                    Theme.of(context).brightness == Brightness.dark;
                return Material(
                  color: isDarkMode
                      ? const Color.fromARGB(255, 20, 20, 26)
                      : Colors.white,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final changed = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoListScreen(
                            folderName: folderName,
                            videos: folderVideos[folderName]!,
                          ),
                        ),
                      );
                      if (changed == true) {
                        _scanFoldersForVideos();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/4.png',
                            width: 50,
                            height: 50,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  folderName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge!.color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${folderVideos[folderName]!.length} ${folderVideos[folderName]!.length == 1 ? 'video' : 'videos'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodySmall!.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showStreamDialog,
        backgroundColor: Colors.blue.shade900,
        child: const Icon(Icons.live_tv, color: Colors.white),
      ),
    );
  }
}
