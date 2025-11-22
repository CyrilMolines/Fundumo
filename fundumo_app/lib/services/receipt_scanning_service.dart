import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'permission_service.dart';

/// Service for scanning receipts using camera and OCR
class ReceiptScanningService {
  ReceiptScanningService({
    PermissionService? permissionService,
    ImagePicker? imagePicker,
  })  : _permissionService = permissionService ?? PermissionService(),
        _imagePicker = imagePicker ?? ImagePicker();

  final PermissionService _permissionService;
  final ImagePicker _imagePicker;
  List<CameraDescription>? _cameras;

  /// Initialize camera
  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      debugPrint('Failed to initialize cameras: $e');
      _cameras = [];
    }
  }

  /// Get available cameras
  List<CameraDescription>? get cameras => _cameras;

  /// Check if camera is available
  bool get isCameraAvailable => _cameras != null && _cameras!.isNotEmpty;

  /// Capture image from camera
  Future<XFile?> captureImage() async {
    // Check camera permission
    final cameraStatus = await _permissionService.checkCameraPermission();
    if (!cameraStatus.isGranted) {
      final requested = await _permissionService.requestCameraPermission();
      if (!requested.isGranted) {
        throw ReceiptScanningException('Camera permission denied');
      }
    }

    if (!isCameraAvailable) {
      throw ReceiptScanningException('No camera available');
    }

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw ReceiptScanningException('Failed to capture image: $e');
    }
  }

  /// Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    // Check storage permission
    final hasPermission = await _permissionService.checkStoragePermission();
    if (!hasPermission) {
      await _permissionService.requestStoragePermission();
      final hasPermissionAfterRequest =
          await _permissionService.checkStoragePermission();
      if (!hasPermissionAfterRequest) {
        throw ReceiptScanningException('Storage permission denied');
      }
    }

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw ReceiptScanningException('Failed to pick image: $e');
    }
  }

  /// Extract text from receipt image using OCR
  Future<ReceiptScanResult> extractTextFromImage(XFile imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final textRecognizer = TextRecognizer();

      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      // Extract structured data from OCR text
      final extractedData = _extractReceiptData(recognizedText.text);

      return ReceiptScanResult(
        imagePath: imageFile.path,
        rawText: recognizedText.text,
        extractedData: extractedData,
      );
    } catch (e) {
      throw ReceiptScanningException('Failed to extract text: $e');
    }
  }

  /// Extract structured data from OCR text
  Map<String, dynamic> _extractReceiptData(String text) {
    final data = <String, dynamic>{};

    // Try to extract total amount
    final totalRegex = RegExp(r'total[:\s]*\$?(\d+\.?\d*)', caseSensitive: false);
    final totalMatch = totalRegex.firstMatch(text);
    if (totalMatch != null) {
      data['total'] = double.tryParse(totalMatch.group(1) ?? '');
    }

    // Try to extract date
    final dateRegex = RegExp(
      r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})',
    );
    final dateMatch = dateRegex.firstMatch(text);
    if (dateMatch != null) {
      final month = int.tryParse(dateMatch.group(1) ?? '');
      final day = int.tryParse(dateMatch.group(2) ?? '');
      final year = int.tryParse(dateMatch.group(3) ?? '');
      if (month != null && day != null && year != null) {
        // Normalize year
        final normalizedYear = year < 100 ? 2000 + year : year;
        data['date'] = DateTime(normalizedYear, month, day);
      }
    }

    // Try to extract merchant name (first line or before date)
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isNotEmpty) {
      data['merchant'] = lines.first.trim();
    }

    return data;
  }

  /// Save image to app directory
  Future<String> saveImage(XFile imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final receiptDir = Directory('${directory.path}/receipts');
      if (!await receiptDir.exists()) {
        await receiptDir.create(recursive: true);
      }

      final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = File('${receiptDir.path}/$fileName');
      await imageFile.saveTo(savedFile.path);

      return savedFile.path;
    } catch (e) {
      throw ReceiptScanningException('Failed to save image: $e');
    }
  }

  /// Delete saved image
  Future<void> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Failed to delete image: $e');
    }
  }
}

class ReceiptScanResult {
  ReceiptScanResult({
    required this.imagePath,
    required this.rawText,
    required this.extractedData,
  });

  final String imagePath;
  final String rawText;
  final Map<String, dynamic> extractedData;
}

class ReceiptScanningException implements Exception {
  ReceiptScanningException(this.message);
  final String message;
  @override
  String toString() => 'ReceiptScanningException: $message';
}

final receiptScanningServiceProvider = Provider<ReceiptScanningService>(
  (ref) => ReceiptScanningService(),
);
