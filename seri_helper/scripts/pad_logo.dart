import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  print('Starting padding process...');
  final inputFile = File('assets/Logo.png');
  
  if (!inputFile.existsSync()) {
    print('Error: Could not find assets/Logo.png');
    return;
  }

  final imageBytes = inputFile.readAsBytesSync();
  final originalImage = img.decodeImage(imageBytes);

  if (originalImage == null) {
    print('Error: Could not decode the image.');
    return;
  }

  // Calculate new padded size (1.6x larger to provide a safe zone)
  final paddedWidth = (originalImage.width * 1.6).toInt();
  final paddedHeight = (originalImage.height * 1.6).toInt();

  // Create a new blank, transparent canvas
  final paddedImage = img.Image(width: paddedWidth, height: paddedHeight);
  img.fill(paddedImage, color: img.ColorRgba8(0, 0, 0, 0));

  // Draw the original image onto the center of the new canvas
  final destX = (paddedWidth - originalImage.width) ~/ 2;
  final destY = (paddedHeight - originalImage.height) ~/ 2;
  
  img.compositeImage(
    paddedImage, 
    originalImage, 
    dstX: destX, 
    dstY: destY
  );

  // Save the result
  final outputFile = File('assets/Logo_padded.png');
  outputFile.writeAsBytesSync(img.encodePng(paddedImage));
  print('Success! Padded logo saved as assets/Logo_padded.png');
}
