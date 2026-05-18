import 'dart:io';
import 'package:share_plus/share_plus.dart';

class VideoShareHelper {
  static Future<void> shareVideo(File videoFile) async {
    try {
      if (await videoFile.exists()) {
        await Share.shareXFiles([XFile(videoFile.path)]);
      } else {
        print('فایل وجود نداره');
      }
    } catch (e) {
      print("خطا در اشتراک‌گذاری ویدیو: $e");
    }
  }
}
