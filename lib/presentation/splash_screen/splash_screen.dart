import 'package:flutter/material.dart';
import 'package:flutter_application_1/presentation/folder_list_screen/folder_list_screen.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) =>  FolderListScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.blue.withOpacity(1),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    'vide',
                    style: TextStyle(
                      fontSize: 130,
                      color: Colors.blue,
                      shadows: [
                        Shadow(
                          color: Colors.blue,
                          offset: Offset(2, 2),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 10,
                    right: 12,
                    bottom: 0,
                  ),
                  child: Container(
                    width: 68,
                    height: 68,
                    child: Image.asset(
                      'assets/images/video.gif',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Padding(
                  padding: EdgeInsets.only(right: 20, bottom: 35),
                  child: Text(
                    'player',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 40,
                      shadows: [
                        Shadow(
                          color: Colors.blue,
                          offset: Offset(2, 2),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(0.0),
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(1),
                    Colors.white.withOpacity(0.9),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
