// Halaman My File - Updated
import 'package:flutter/material.dart';
import 'package:iTen/constants/app_colors.dart';
import 'package:iTen/models/animation_model.dart';
import 'package:iTen/services/default_animations_service.dart';
import 'package:iTen/services/export_import_service.dart';
import 'package:iTen/services/firebase_data_service.dart';

class MyFilePage extends StatefulWidget {
  const MyFilePage({super.key});

  @override
  State<MyFilePage> createState() => _MyFilePageState();
}

class _MyFilePageState extends State<MyFilePage> {
  final FirebaseDataService _firebaseService = FirebaseDataService();
  final DefaultAnimationsService _defaultAnimationsService =
      DefaultAnimationsService();
final ExportImportService _exportImportService = ExportImportService();

  // Data dari user selections dan default animations
  List<AnimationModel> _userSelectedFiles = [];
  List<AnimationModel> _defaultFiles = [];
  final Set<int> _selectedFiles = {};
  final Set<int> _selectedDefaultFiles = {};
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAllFiles();
  }
// Export selected files
void _exportSelectedFiles() async {
  if (_selectedFiles.isEmpty) return;

  final selectedAnimations = _selectedFiles
      .map((index) => _userSelectedFiles[index - _defaultFiles.length])
      .toList();

  try {
    final success = await _exportImportService.exportMultipleAnimations(
      selectedAnimations,
      context: context,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.neonGreen,
          content: Text(
            'Exported ${selectedAnimations.length} animation(s) successfully!',
            style: TextStyle(
              color: AppColors.primaryBlack,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
      
      // Clear selection setelah export
      setState(() {
        _selectedFiles.clear();
      });
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          'Export failed: $e',
          style: TextStyle(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// Import files
void _importFiles() async {
  try {
    final result = await _exportImportService.importAnimationsFromFile();

    if (result.isCancelled) {
      return;
    }

    if (!result.isSuccess) {
      throw Exception(result.error);
    }

    // Refresh data setelah import
    await _refreshData();

    // Show success dialog
    _showImportResult(result);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          'Import failed: $e',
          style: TextStyle(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// Show import result dialog
void _showImportResult(ImportResult result) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.darkGrey,
      title: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppColors.neonGreen,
          ),
          SizedBox(width: 8),
          Text(
            'Import Successful',
            style: TextStyle(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Successfully imported ${result.successfullyImported} animation(s)',
            style: TextStyle(color: AppColors.pureWhite),
          ),
          if (result.duplicates > 0) ...[
            SizedBox(height: 8),
            Text(
              '${result.duplicates} duplicate(s) were renamed',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
              ),
            ),
          ],
          SizedBox(height: 12),
          if (result.package != null) ...[
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlack,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'File Format:',
                    style: TextStyle(
                      color: AppColors.neonGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '[AnimationName]_[Channel]C_[Length]L_[Date]',
                    style: TextStyle(
                      color: AppColors.pureWhite.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                  SizedBox(height: 4),
                  if (result.package!.animations.length == 1) ...[
                    Text(
                      'Example: "MyAnimation_8C_10L_20231215_1430.iten"',
                      style: TextStyle(
                        color: AppColors.pureWhite.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            setState(() {
              _selectedFiles.clear();
            });
          },
          child: Text(
            'OK',
            style: TextStyle(color: AppColors.neonGreen),
          ),
        ),
      ],
    ),
  );
}
// Export all user animations
void _exportAllUserAnimations() async {
  try {
    final success = await _exportImportService.exportAllUserAnimations(
      context: context,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.neonGreen,
          content: Text(
            'All user animations exported successfully!',
            style: TextStyle(
              color: AppColors.primaryBlack,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          'Export failed: $e',
          style: TextStyle(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
  // Load data dari semua sumber
  Future<void> _loadAllFiles() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Initialize default animations
      await _defaultAnimationsService.initializeDefaultAnimations();

      // Load data dari berbagai sumber
      final selectedFiles = await _firebaseService.getUserSelectedAnimations();
      final defaultFiles = await _defaultAnimationsService
          .getDefaultAnimations();

      setState(() {
        _userSelectedFiles = selectedFiles;
        _defaultFiles = defaultFiles;
        _isLoading = false;
      });

      print(
        '✅ Loaded ${_userSelectedFiles.length} user files + ${_defaultFiles.length} default files',
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading files: $e';
        _isLoading = false;
      });
      print('❌ Error loading files: $e');
    }
  }

  // Refresh data
  Future<void> _refreshData() async {
    await _loadAllFiles();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.neonGreen,
        content: const Text(
          'Files refreshed!',
          style: TextStyle(
            color: AppColors.primaryBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Check if file is default (tidak bisa dihapus)
  bool _isDefaultFile(int index) {
    return index < _defaultFiles.length;
  }

  // Get file by index (menggabungkan default + user files)
  AnimationModel _getFile(int index) {
    if (index < _defaultFiles.length) {
      return _defaultFiles[index];
    } else {
      return _userSelectedFiles[index - _defaultFiles.length];
    }
  }

  // Get total files count
  int get _totalFiles => _defaultFiles.length + _userSelectedFiles.length;

  @override
 @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: Column(
        children: [
          // Header dengan styling matrix
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.darkGrey,
                  AppColors.primaryBlack,
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.neonGreen.withOpacity(0.3),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonGreen.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                // Title dengan icon
                Icon(
                  Icons.folder_special,
                  color: AppColors.neonGreen,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'MY FILES',
                  style: TextStyle(
                    color: AppColors.neonGreen,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlack,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.neonGreen.withOpacity(0.5),
                    ),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${_defaultFiles.length}',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: ' + ',
                          style: TextStyle(
                            color: AppColors.pureWhite.withOpacity(0.5),
                            fontSize: 10,
                          ),
                        ),
                        TextSpan(
                          text: '${_userSelectedFiles.length}',
                          style: TextStyle(
                            color: AppColors.neonGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Options Bar (muncul ketika ada file yang dipilih)
// Options Bar (muncul ketika ada file yang dipilih)
if (_selectedFiles.isNotEmpty || _selectedDefaultFiles.isNotEmpty)
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.darkGrey,
      border: Border(
        bottom: BorderSide(
          color: AppColors.neonGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // DELETE Button (hanya untuk non-default files)
        if (_selectedFiles.isNotEmpty)
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              height: 45,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withOpacity(0.8),
                    Colors.red.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _deleteSelectedFiles,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.pureWhite,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_forever, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'DELETE',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // EXPORT Button (untuk selected files)
        if (_selectedFiles.isNotEmpty)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              height: 45,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withOpacity(0.8),
                    Colors.purple.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _exportSelectedFiles,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.pureWhite,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.import_export, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'EXPORT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  ),
          // Loading Indicator
          if (_isLoading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.darkGrey,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.neonGreen.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: AppColors.neonGreen,
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Loading your files...',
                            style: TextStyle(
                              color: AppColors.pureWhite,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please wait while we load your animations',
                            style: TextStyle(
                              color: AppColors.pureWhite.withOpacity(0.7),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          // Error Message
          else if (_errorMessage.isNotEmpty)
            Expanded(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.darkGrey,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Oops! Something went wrong',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage,
                        style: TextStyle(
                          color: AppColors.pureWhite,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 45,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.neonGreen.withOpacity(0.9),
                              AppColors.neonGreen.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ElevatedButton(
                          onPressed: _refreshData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: AppColors.primaryBlack,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'TRY AGAIN',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          // Empty State
          else if (_totalFiles == 0)
            Expanded(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.darkGrey,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.neonGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.folder_open,
                        color: AppColors.neonGreen.withOpacity(0.5),
                        size: 64,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No Animations Found',
                        style: TextStyle(
                          color: AppColors.pureWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your animation library is empty.\nDownload animations from Cloud Files to get started.',
                        style: TextStyle(
                          color: AppColors.pureWhite.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        height: 45,
                        width: 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.neonGreen.withOpacity(0.9),
                              AppColors.neonGreen.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.neonGreen.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigate to Cloud Files page
                            // Navigator.push(context, MaterialPageRoute(builder: (context) => CloudFilePage()));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: AppColors.primaryBlack,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'GO TO CLOUD FILES',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          // List File Animasi (Default + User Selections)
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _totalFiles,
                itemBuilder: (context, index) {
                  final file = _getFile(index);
                  final isDefault = _isDefaultFile(index);
                  final isSelected = isDefault
                      ? _selectedDefaultFiles.contains(index)
                      : _selectedFiles.contains(index);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.darkGrey,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? (isDefault ? Colors.blue : AppColors.neonGreen)
                            : AppColors.neonGreen.withOpacity(0.2),
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                        if (isSelected)
                          BoxShadow(
                            color: (isDefault ? Colors.blue : AppColors.neonGreen)
                                .withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: isDefault
                          ? Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.blue),
                              ),
                              child: Icon(
                                Icons.verified_user,
                                color: Colors.blue,
                                size: 24,
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.neonGreen
                                    : AppColors.neonGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.neonGreen
                                      : AppColors.neonGreen.withOpacity(0.3),
                                ),
                              ),
                              child: Checkbox(
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedFiles.add(index);
                                    } else {
                                      _selectedFiles.remove(index);
                                    }
                                  });
                                },
                                checkColor: AppColors.primaryBlack,
                                fillColor: MaterialStateProperty.all(
                                  isSelected
                                      ? AppColors.neonGreen
                                      : Colors.transparent,
                                ),
                                side: BorderSide(
                                  color: AppColors.neonGreen.withOpacity(0.5),
                                ),
                              ),
                            ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              file.name,
                              style: TextStyle(
                                color: AppColors.pureWhite,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue),
                              ),
                              child: Text(
                                'DEFAULT',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            file.description.isEmpty
                                ? 'No description available'
                                : file.description,
                            style: TextStyle(
                              color: AppColors.pureWhite.withOpacity(0.7),
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Channel Count
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.neonGreen.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${file.channelCount}C',
                                  style: TextStyle(
                                    color: AppColors.neonGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),

                              // Animation Length
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${file.animationLength}L',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),

                              // Frame Count
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${file.totalFrames}F',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),

                              // Validation Status

                            ],
                          ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.animation,
                        color: isDefault ? Colors.blue : AppColors.neonGreen,
                        size: 24,
                      ),
                      onTap: () {
  if (!isDefault) {
    setState(() {
      if (_selectedFiles.contains(index)) {
        _selectedFiles.remove(index);
      } else {
        _selectedFiles.add(index);
      }
    });
  }
},

// Dan untuk default files, bisa ditambahkan feedback:
onLongPress: () {
  _previewFile(file, isDefault);
  if (isDefault) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.blue,
        content: Text(
          'Default animation "${file.name}" - cannot be modified',
          style: TextStyle(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
},
                    ),
                  );
                },
              ),
            ),
        ],
      ),

      // Refresh FAB dengan styling
// Ganti floatingActionButton dengan ini:
// Floating Action Button Section
floatingActionButton: _isLoading
    ? null
    : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Import Button - selalu visible
          Container(
            margin: const EdgeInsets.only(bottom: 8, right: 16),
            child: FloatingActionButton(
              onPressed: _importFiles,
              backgroundColor: Colors.blue,
              foregroundColor: AppColors.pureWhite,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              heroTag: 'import_fab',
              child: const Icon(Icons.file_download, size: 24),
            ),
          ),
          // Export All Button - hanya visible jika ada user animations
          if (_userSelectedFiles.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8, right: 16),
              child: FloatingActionButton(
                onPressed: _exportAllUserAnimations,
                backgroundColor: Colors.purple,
                foregroundColor: AppColors.pureWhite,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                heroTag: 'export_all_fab',
                child: const Icon(Icons.archive, size: 24),
              ),
            ),
          // Refresh Button - selalu visible
          Container(
            margin: const EdgeInsets.only(bottom: 16, right: 16),
            child: FloatingActionButton(
              onPressed: _refreshData,
              backgroundColor: AppColors.neonGreen,
              foregroundColor: AppColors.primaryBlack,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              heroTag: 'refresh_fab',
              child: const Icon(Icons.refresh, size: 24),
            ),
          ),
        ],
      ),
    );
  }
  void _deleteSelectedFiles() {
  if (_selectedFiles.isEmpty) return;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.darkGrey,
      title: Text(
        'Delete Files',
        style: TextStyle(color: AppColors.pureWhite),
      ),
      content: Text(
        'Are you sure you want to delete ${_selectedFiles.length} file(s)?',
        style: TextStyle(color: AppColors.pureWhite),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: AppColors.neonGreen)),
        ),
        ElevatedButton(
          onPressed: () async {
            // Hapus file dari user selections (hanya non-default)
            final filesToRemove = _selectedFiles
                .map(
                  (index) => _userSelectedFiles[index - _defaultFiles.length],
                )
                .toList();

            for (final file in filesToRemove) {
              await _firebaseService.removeUserSelectedAnimation(file.name);
            }

            setState(() {
              // Update local list
              _userSelectedFiles.removeWhere(
                (file) => filesToRemove.any(
                  (removedFile) => removedFile.name == file.name,
                ),
              );
              _selectedFiles.clear(); // Clear selection setelah delete
            });

            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.neonGreen,
                content: Text(
                  '${filesToRemove.length} file(s) deleted successfully!',
                  style: TextStyle(
                    color: AppColors.primaryBlack,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('DELETE'),
        ),
      ],
    ),
  );
}

  void _previewFile(AnimationModel file, bool isDefault) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkGrey,
        title: Row(
          children: [
            Text(
              file.name,
              style: TextStyle(
                color: isDefault ? Colors.blue : AppColors.neonGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isDefault) ...[
              const SizedBox(width: 8),
              Icon(Icons.security, color: Colors.blue, size: 20),
            ],
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDefault)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Default Animation - Cannot be deleted',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Description
              Text(
                'Description: ${file.description.isEmpty ? "No description" : file.description}',
                style: TextStyle(color: AppColors.pureWhite),
              ),
              const SizedBox(height: 12),

              // Technical Details
              _buildDetailRow('Channel Count', '${file.channelCount}'),
              _buildDetailRow('Animation Length', '${file.animationLength}'),
              _buildDetailRow('Total Frames', '${file.totalFrames}'),
              _buildDetailRow('Delay Data', file.delayData),
              _buildDetailRow('Validation', file.isValid ? 'Valid' : 'Invalid'),
              _buildDetailRow('Type', isDefault ? 'Default' : 'User'),

              const SizedBox(height: 12),

              // Frame Data Preview
              if (file.frameData.isNotEmpty) ...[
                Text(
                  'Frame Data Preview:',
                  style: TextStyle(
                    color: isDefault ? Colors.blue : AppColors.neonGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlack,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    file.frameData.take(3).join('\n'),
                    style: TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 10,
                      fontFamily: 'Monospace',
                    ),
                    maxLines: 6,
                  ),
                ),
                if (file.frameData.length > 3)
                  Text(
                    '... and ${file.frameData.length - 3} more frames',
                    style: TextStyle(
                      color: AppColors.pureWhite.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CLOSE', style: TextStyle(color: AppColors.neonGreen)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(color: AppColors.pureWhite.withOpacity(0.7)),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
