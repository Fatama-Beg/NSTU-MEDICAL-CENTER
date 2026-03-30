import 'package:media_store_plus/media_store_plus.dart';

Future<String?> saveFileToMediaStore(String tempFilePath) async {
  await MediaStore.ensureInitialized();
  MediaStore.appFolder = 'Dishari';

  final info = await MediaStore().saveFile(
    tempFilePath: tempFilePath,
    dirType: DirType.download,
    dirName: DirName.download,
  );
  return info?.uri.toString();
}
