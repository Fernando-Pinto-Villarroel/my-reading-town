abstract class ImagePort {
  Future<String?> pickFromGallery();
  Future<String?> pickFromCamera();
  Future<String?> saveImageFromUrl(String url);
  Future<void> deleteImage(String path);
}
