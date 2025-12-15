// services/export_import_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:iTen/models/animation_model.dart';
import 'package:iTen/models/export_model.dart';
import 'package:iTen/services/preferences_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportImportService {
  static final ExportImportService _instance = ExportImportService._internal();
  factory ExportImportService() => _instance;
  ExportImportService._internal();

  final PreferencesService _prefsService = PreferencesService();
  static const String _fileExtension = 'iten';
  static const String _mimeType = 'application/iten';

  // ============ EXPORT METHODS ============

  // Export single animation
  Future<bool> exportSingleAnimation(
    AnimationModel animation, {
    String? fileName,
    BuildContext? context,
  }) async {
    try {
      final package = ExportPackage(
        animations: [animation],
        deviceName: await _getDeviceName(),
        metadata: {
          'type': 'single',
          'animationName': animation.name,
          'channelCount': animation.channelCount,
          'animationLength': animation.animationLength,
        },
      );

      // Generate nama file otomatis
      final autoFileName = _generateFileName(package);
      return await _exportPackage(package, fileName: fileName ?? autoFileName, context: context);
    } catch (e) {
      print('❌ Error exporting single animation: $e');
      return false;
    }
  }

  // Export multiple animations
  Future<bool> exportMultipleAnimations(
    List<AnimationModel> animations, {
    String? fileName,
    BuildContext? context,
  }) async {
    try {
      if (animations.isEmpty) {
        throw Exception('No animations to export');
      }

      final package = ExportPackage(
        animations: animations,
        deviceName: await _getDeviceName(),
        metadata: {
          'type': 'multiple',
          'totalAnimations': animations.length,
          'totalFrames': animations.fold(0, (sum, anim) => sum + anim.totalFrames),
        },
      );

      // Generate nama file otomatis
      final autoFileName = _generateFileName(package);
      return await _exportPackage(package, fileName: fileName ?? autoFileName, context: context);
    } catch (e) {
      print('❌ Error exporting multiple animations: $e');
      return false;
    }
  }

  // Export all user animations
  Future<bool> exportAllUserAnimations({BuildContext? context}) async {
    try {
      final userAnimations = await _prefsService.getUserSelectedAnimations();
      
      if (userAnimations.isEmpty) {
        throw Exception('No user animations found to export');
      }

      final package = ExportPackage(
        animations: userAnimations,
        deviceName: await _getDeviceName(),
        metadata: {
          'type': 'all_user',
          'totalAnimations': userAnimations.length,
        },
      );

      // Generate nama file otomatis
      final autoFileName = _generateFileName(
        package, 
        customName: 'iTen_User_Collection'
      );
      return await _exportPackage(
        package,
        fileName: autoFileName,
        context: context,
      );
    } catch (e) {
      print('❌ Error exporting all user animations: $e');
      return false;
    }
  }

  // Internal export method
  Future<bool> _exportPackage(
    ExportPackage package, {
    String? fileName,
    BuildContext? context,
  }) async {
    try {
      // Validasi package
      if (!package.isValid) {
        throw Exception('Invalid package: No valid animations to export');
      }

      // Create file content dengan pretty JSON
      final jsonString = JsonEncoder.withIndent('  ').convert(package.toJson());
      final bytes = utf8.encode(jsonString);

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      
      // Generate nama file sesuai format
      final generatedFileName = _generateFileName(package);
      final finalFileName = fileName ?? generatedFileName;
      final filePath = '${tempDir.path}/$finalFileName.$_fileExtension';

      // Write file
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      print('💾 Export file created: $filePath');
      print('📦 Package summary: ${package.summary}');
      print('📁 File name: $finalFileName');
      print('📊 File size: ${bytes.length} bytes');

      // Share file
      if (context != null) {
        await _shareFile(file, context);
      }

      return true;
    } catch (e) {
      print('❌ Error in _exportPackage: $e');
      return false;
    }
  }

  // ============ IMPORT METHODS ============

  // Import animations from file
  Future<ImportResult> importAnimationsFromFile() async {
    try {
      print('📥 Starting import process...');

      // Pick file dengan error handling yang lebih baik
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [_fileExtension],
        allowMultiple: false,
        withData: true, // Pastikan data dibaca
        withReadStream: false,
      ).catchError((error) {
        print('❌ File picker error: $error');
        throw Exception('Failed to pick file: $error');
      });

      if (result == null) {
        print('📭 File picker cancelled by user');
        return ImportResult.cancelled();
      }

      if (result.files.isEmpty) {
        print('❌ No files selected');
        throw Exception('No file selected');
      }

      final platformFile = result.files.first;
      print('📄 Selected file: ${platformFile.name}');
      print('📊 File size: ${platformFile.size} bytes');
      print('📁 File path: ${platformFile.path}');

      // Validasi file size
      if (platformFile.size == null || platformFile.size! <= 0) {
        print('❌ File is empty (size: ${platformFile.size})');
        throw Exception('File is empty');
      }

      // Handle data dari bytes atau path
      List<int> fileBytes;

      if (platformFile.bytes != null && platformFile.bytes!.isNotEmpty) {
        // Gunakan bytes langsung dari file picker
        fileBytes = platformFile.bytes!;
        print('✅ Using bytes from file picker (${fileBytes.length} bytes)');
      } else if (platformFile.path != null) {
        // Baca dari path file
        final file = File(platformFile.path!);
        if (await file.exists()) {
          fileBytes = await file.readAsBytes();
          print('✅ Using bytes from file path (${fileBytes.length} bytes)');
        } else {
          throw Exception('File does not exist at path: ${platformFile.path}');
        }
      } else {
        throw Exception('No file data available (bytes or path)');
      }

      // Validasi bytes
      if (fileBytes.isEmpty) {
        throw Exception('File bytes are empty');
      }

      print('🔍 Parsing file content...');

      // Parse file content dengan error handling
      final jsonString = utf8.decode(fileBytes);
      
      if (jsonString.trim().isEmpty) {
        throw Exception('File content is empty after decoding');
      }

      print('📝 JSON content length: ${jsonString.length} characters');

      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      
      if (jsonMap.isEmpty) {
        throw Exception('JSON object is empty');
      }

      print('✅ JSON parsed successfully, keys: ${jsonMap.keys}');

      // Create package from JSON
      final package = ExportPackage.fromJson(jsonMap);

      if (!package.isValid) {
        throw Exception('Invalid package file: No valid animations found');
      }

      print('📦 Importing package: ${package.summary}');

      // Save animations to preferences
      final savedAnimations = await _saveImportedAnimations(package.animations);

      return ImportResult.success(
        package: package,
        savedAnimations: savedAnimations,
        totalAnimations: package.animations.length,
      );
    } catch (e) {
      print('❌ Error importing animations: $e');
      print('Stack trace: ${e.toString()}');
      return ImportResult.error(error: e.toString());
    }
  }

  // Import animations from bytes (for testing)
  Future<ImportResult> importAnimationsFromBytes(List<int> bytes) async {
    try {
      if (bytes.isEmpty) {
        throw Exception('Bytes are empty');
      }

      final jsonString = utf8.decode(bytes);
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final package = ExportPackage.fromJson(jsonMap);

      if (!package.isValid) {
        throw Exception('Invalid package file');
      }

      final savedAnimations = await _saveImportedAnimations(package.animations);

      return ImportResult.success(
        package: package,
        savedAnimations: savedAnimations,
        totalAnimations: package.animations.length,
      );
    } catch (e) {
      print('❌ Error importing from bytes: $e');
      return ImportResult.error(error: e.toString());
    }
  }

  // ============ INTERNAL METHODS ============

  // Save imported animations to preferences
  Future<List<AnimationModel>> _saveImportedAnimations(
    List<AnimationModel> importedAnimations,
  ) async {
    try {
      final currentAnimations = await _prefsService.getUserSelectedAnimations();
      final savedAnimations = <AnimationModel>[];

      for (final importedAnim in importedAnimations) {
        // Check if animation already exists
        final existingIndex = currentAnimations.indexWhere(
          (anim) => anim.name == importedAnim.name,
        );

        if (existingIndex >= 0) {
          // Generate unique name for duplicate
          final uniqueName = _generateUniqueName(importedAnim.name, currentAnimations);
          final uniqueAnim = importedAnim.copyWith(name: uniqueName);
          
          await _prefsService.addUserSelectedAnimation(uniqueAnim);
          savedAnimations.add(uniqueAnim);
          print('🔄 Renamed duplicate: "${importedAnim.name}" -> "$uniqueName"');
        } else {
          await _prefsService.addUserSelectedAnimation(importedAnim);
          savedAnimations.add(importedAnim);
          print('✅ Imported: "${importedAnim.name}"');
        }
      }

      print('💾 Imported ${savedAnimations.length} animations to preferences');
      return savedAnimations;
    } catch (e) {
      print('❌ Error saving imported animations: $e');
      rethrow;
    }
  }

  // Generate unique name for duplicate animations
  String _generateUniqueName(String baseName, List<AnimationModel> existingAnimations) {
    int counter = 1;
    String newName = '$baseName (Imported)';

    while (existingAnimations.any((anim) => anim.name == newName)) {
      counter++;
      newName = '$baseName (Imported $counter)';
    }

    return newName;
  }

  // Generate nama file sesuai format
  String _generateFileName(ExportPackage package, {String? customName}) {
    if (package.animations.length == 1) {
      // Single animation
      final animation = package.animations.first;
      final date = _formatDate(package.exportDate);
      // Clean nama animasi untuk filename (hapus karakter tidak valid)
      final cleanName = _cleanFileName(animation.name);
      return '${cleanName}_${animation.channelCount}C_${animation.animationLength}L_$date';
    } else {
      // Multiple animations
      final date = _formatDate(package.exportDate);
      final baseName = customName ?? 'iTen_Animations';
      final totalChannels = package.animations.map((a) => a.channelCount).reduce((a, b) => a + b);
      final totalFrames = package.animations.fold(0, (sum, anim) => sum + anim.animationLength);
      return '${baseName}_${package.animations.length}A_${totalChannels}C_${totalFrames}F_$date';
    }
  }

  // Clean nama file dari karakter tidak valid
  String _cleanFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
               .replaceAll(RegExp(r'\s+'), '_')
               .replaceAll(RegExp(r'_+'), '_')
               .trim();
  }

  // Format tanggal untuk nama file
  String _formatDate(DateTime date) {
    return '${date.year}${_twoDigits(date.month)}${_twoDigits(date.day)}_${_twoDigits(date.hour)}${_twoDigits(date.minute)}';
  }

  String _twoDigits(int n) {
    if (n >= 10) return '$n';
    return '0$n';
  }

  // Get device name
  Future<String> _getDeviceName() async {
    final config = await _prefsService.getDeviceConfig();
    return config?.devID ?? 'iTen Device';
  }

  // Share file
  Future<void> _shareFile(File file, BuildContext context) async {
    try {
      final xFile = XFile(file.path, mimeType: _mimeType);
      await Share.shareXFiles(
        [xFile],
        subject: 'iTen Animation Export',
        text: 'Sharing iTen animation export file',
      );
    } catch (e) {
      print('❌ Error sharing file: $e');
      // Fallback: show snackbar with file path
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File saved to: ${file.path}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Validate file extension
  bool isValidFileExtension(String path) {
    return path.toLowerCase().endsWith('.$_fileExtension');
  }

  // Get file size in readable format
  String getFileSizeString(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

// Result class untuk import operation
class ImportResult {
  final bool isSuccess;
  final bool isCancelled;
  final String? error;
  final ExportPackage? package;
  final List<AnimationModel>? savedAnimations;
  final int? totalAnimations;

  ImportResult({
    required this.isSuccess,
    required this.isCancelled,
    this.error,
    this.package,
    this.savedAnimations,
    this.totalAnimations,
  });

  factory ImportResult.success({
    required ExportPackage package,
    required List<AnimationModel> savedAnimations,
    required int totalAnimations,
  }) {
    return ImportResult(
      isSuccess: true,
      isCancelled: false,
      package: package,
      savedAnimations: savedAnimations,
      totalAnimations: totalAnimations,
    );
  }

  factory ImportResult.error({required String error}) {
    return ImportResult(
      isSuccess: false,
      isCancelled: false,
      error: error,
    );
  }

  factory ImportResult.cancelled() {
    return ImportResult(
      isSuccess: false,
      isCancelled: true,
    );
  }

  int get successfullyImported => savedAnimations?.length ?? 0;
  int get duplicates => (totalAnimations ?? 0) - successfullyImported;

  String get summary {
    if (isCancelled) return 'Import cancelled';
    if (!isSuccess) return 'Import failed: $error';
    return 'Imported $successfullyImported animations ($duplicates duplicates handled)';
  }
}