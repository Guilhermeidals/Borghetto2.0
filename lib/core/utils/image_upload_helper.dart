import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageUploadHelper {
  const ImageUploadHelper._();

  static Future<File> prepareXFileForUpload(XFile image) async {
    return prepareFileForUpload(File(image.path));
  }

  static Future<File> prepareFileForUpload(File imageFile) async {
    final targetPath =
        '${imageFile.path}_fixed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final fixedImage = await FlutterImageCompress.compressAndGetFile(
      imageFile.absolute.path,
      targetPath,
      quality: 92,
      format: CompressFormat.jpeg,
      autoCorrectionAngle: true,
      keepExif: false,
    );

    if (fixedImage == null) {
      return imageFile;
    }

    return File(fixedImage.path);
  }
}