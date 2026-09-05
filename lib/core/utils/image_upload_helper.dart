import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageUploadHelper {
  const ImageUploadHelper._();

  static Future<File> prepareXFileForUpload(XFile image) async {
    return prepareFileForUpload(File(image.path));
  }

  static Future<File> prepareFileForUpload(File imageFile) async {
    final targetPath =
        '${imageFile.path}_fixed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      final fixedImage = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: 92,
        format: CompressFormat.jpeg,
        autoCorrectionAngle: true,
        keepExif: false,
      );

      if (fixedImage != null) {
        return File(fixedImage.path);
      }
    } catch (error, stackTrace) {
      debugPrint('Falha ao preparar imagem para upload: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    if (await imageFile.exists()) {
      return imageFile;
    }

    throw const FileSystemException(
      'O arquivo selecionado não está mais disponível.',
    );
  }
}
