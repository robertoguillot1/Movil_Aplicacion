// v1.6 - services/receipt_service.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';

class ReceiptService {
  static final ImagePicker _picker = ImagePicker();

  /// Toma una foto usando la cámara
  static Future<String?> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        return await _saveReceiptImage(image);
      }
      return null;
    } catch (e) {
      debugPrint('Error taking photo: $e');
      return null;
    }
  }

  /// Selecciona una imagen de la galería
  static Future<String?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        return await _saveReceiptImage(image);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
      return null;
    }
  }

  /// Guarda la imagen en el directorio de documentos de la app
  static Future<String> _saveReceiptImage(XFile image) async {
    final directory = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory('${directory.path}/receipts');
    
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }
    
    final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final filePath = '${receiptsDir.path}/$fileName';
    
    final File savedFile = await File(image.path).copy(filePath);
    return savedFile.path;
  }

  /// Elimina un comprobante
  static Future<bool> deleteReceipt(String? receiptPath) async {
    if (receiptPath == null || receiptPath.isEmpty) return true;
    
    try {
      final file = File(receiptPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting receipt: $e');
      return false;
    }
  }

  /// Verifica si existe un comprobante
  static Future<bool> receiptExists(String? receiptPath) async {
    if (receiptPath == null || receiptPath.isEmpty) return false;
    
    try {
      final file = File(receiptPath);
      return await file.exists();
    } catch (e) {
      debugPrint('Error checking receipt: $e');
      return false;
    }
  }
}

