import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<Directory> getMoneyManagerDownloadDirectory() async {
  if (Platform.isAndroid) {
    final primaryDownload = Directory('/storage/emulated/0/Download');
    if (await primaryDownload.exists()) {
      final target = Directory(p.join(primaryDownload.path, 'Money Manager'));
      await target.create(recursive: true);
      return target;
    }

    final external = await getExternalStorageDirectory();
    final base = external ?? await getApplicationDocumentsDirectory();
    final target = Directory(p.join(base.path, 'Money Manager'));
    await target.create(recursive: true);
    return target;
  }

  if (Platform.isIOS) {
    final base = await getApplicationDocumentsDirectory();
    final target = Directory(p.join(base.path, 'Money Manager'));
    await target.create(recursive: true);
    return target;
  }

  final downloads = await getDownloadsDirectory();
  final base = downloads ?? await getApplicationDocumentsDirectory();
  final target = Directory(p.join(base.path, 'Money Manager'));
  await target.create(recursive: true);
  return target;
}
