import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final _storage = FirebaseStorage.instance;

  static Future<String> uploadItemImage({
    required File file,
    required String userEmail,
    required String fileName,
  }) async {
    final ref = _storage
        .ref()
        .child('items')
        .child(userEmail)
        .child(fileName);

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
}
