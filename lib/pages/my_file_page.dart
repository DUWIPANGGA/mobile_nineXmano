// Halaman My File - Updated
import 'package:flutter/material.dart';
import 'package:ninexmano_matrix/constants/app_colors.dart';
import 'package:ninexmano_matrix/models/animation_model.dart';
import 'package:ninexmano_matrix/services/default_animations_service.dart';
import 'package:ninexmano_matrix/services/firebase_data_service.dart';

class MyFilePage extends StatefulWidget {
  const MyFilePage({super.key});

  @override
  State<MyFilePage> createState() => _MyFilePageState();
}

class _MyFilePageState extends State<MyFilePage> {
  final FirebaseDataService _firebaseService = FirebaseDataService();
  final DefaultAnimationsService _defaultAnimationsService =
      DefaultAnimationsService();

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: Column(
        children: [
          // Di bagian App Bar Custom di MyFilePage, ganti dengan ini:
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.darkGrey,
            child: Row(
              children: [
                // Title
                Text(
                  'MY FILES',
                  style: TextStyle(
                    color: AppColors.neonGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),

                // Cloud Identifier Status
                FutureBuilder(
                  future: _firebaseService.getCloudEmail(),
                  builder: (context, snapshot) {
                    final email = snapshot.data ?? 'CC';
                    final isUsingCC = email == 'CC';

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isUsingCC
                            ? Colors.blue.withOpacity(0.2)
                            : AppColors.neonGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isUsingCC ? Colors.blue : AppColors.neonGreen,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isUsingCC ? Icons.cloud : Icons.email,
                            color: isUsingCC
                                ? Colors.blue
                                : AppColors.neonGreen,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            isUsingCC ? 'Using CC' : 'Using Email',
                            style: TextStyle(
                              color: isUsingCC
                                  ? Colors.blue
                                  : AppColors.neonGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Refresh Button
                IconButton(
                  onPressed: _isLoading ? null : _refreshData,
                  icon: Icon(
                    Icons.refresh,
                    color: _isLoading
                        ? AppColors.pureWhite.withOpacity(0.5)
                        : AppColors.neonGreen,
                  ),
                  tooltip: 'Refresh files',
                ),

                // Statistics
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlack,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.neonGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${_defaultFiles.length} default + ${_userSelectedFiles.length} user',
                    style: TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Options Bar (muncul ketika ada file yang dipilih)
          if (_selectedFiles.isNotEmpty || _selectedDefaultFiles.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppColors.darkGrey,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // DELETE Button (hanya untuk non-default files)
                  if (_selectedFiles.isNotEmpty)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: ElevatedButton(
                          onPressed: _deleteSelectedFiles,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: AppColors.pureWhite,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete, size: 18),
                              SizedBox(width: 4),
                              Text('DELETE'),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // SAVE TO CLOUD Button
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        left: _selectedFiles.isNotEmpty ? 8 : 0,
                      ),
                      child: ElevatedButton(
                        onPressed: _saveToCloud,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonGreen,
                          foregroundColor: AppColors.primaryBlack,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload, size: 18),
                            SizedBox(width: 4),
                            Text('SAVE TO CLOUD'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Separator Line
          Container(height: 1, color: AppColors.neonGreen.withOpacity(0.3)),

          // Loading Indicator
          if (_isLoading)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.neonGreen),
                    SizedBox(height: 16),
                    Text(
                      'Loading your files...',
                      style: TextStyle(color: AppColors.pureWhite),
                    ),
                  ],
                ),
              ),
            )
          // Error Message
          else if (_errorMessage.isNotEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _refreshData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonGreen,
                        foregroundColor: AppColors.primaryBlack,
                      ),
                      child: const Text('RETRY'),
                    ),
                  ],
                ),
              ),
            )
          // Empty State
          else if (_totalFiles == 0)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open,
                      color: AppColors.pureWhite.withOpacity(0.5),
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No files found',
                      style: TextStyle(
                        color: AppColors.pureWhite.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Download animations from Cloud Files to get started',
                      style: TextStyle(
                        color: AppColors.pureWhite.withOpacity(0.5),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to Cloud Files page
                        // Navigator.push(context, MaterialPageRoute(builder: (context) => CloudFilePage()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonGreen,
                        foregroundColor: AppColors.primaryBlack,
                      ),
                      child: const Text('GO TO CLOUD FILES'),
                    ),
                  ],
                ),
              ),
            )
          // List File Animasi (Default + User Selections)
          else
            Expanded(
              child: ListView.builder(
                itemCount: _totalFiles,
                itemBuilder: (context, index) {
                  final file = _getFile(index);
                  final isDefault = _isDefaultFile(index);
                  final isSelected = isDefault
                      ? _selectedDefaultFiles.contains(index)
                      : _selectedFiles.contains(index);

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.darkGrey,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? (isDefault ? Colors.blue : AppColors.neonGreen)
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: isDefault
                          ? Icon(Icons.security, color: Colors.blue, size: 24)
                          : Checkbox(
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
                                AppColors.neonGreen,
                              ),
                            ),
                      title: Row(
                        children: [
                          Text(
                            file.name,
                            style: TextStyle(
                              color: AppColors.pureWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
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
                          Text(
                            file.description.isEmpty
                                ? 'No description'
                                : file.description,
                            style: TextStyle(
                              color: AppColors.pureWhite.withOpacity(0.8),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              // Channel Count
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.neonGreen.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${file.channelCount}C',
                                  style: TextStyle(
                                    color: AppColors.neonGreen,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Animation Length
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${file.animationLength}L',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Frame Count
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${file.totalFrames}F',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),

                              // Validation Status
                              Icon(
                                file.isValid ? Icons.check_circle : Icons.error,
                                color: file.isValid
                                    ? AppColors.neonGreen
                                    : Colors.red,
                                size: 16,
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.animation,
                        color: isDefault ? Colors.blue : AppColors.neonGreen,
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
                      onLongPress: () {
                        _previewFile(file, isDefault);
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),

      // Refresh indicator
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton(
              onPressed: _refreshData,
              backgroundColor: AppColors.neonGreen,
              foregroundColor: AppColors.primaryBlack,
              mini: true,
              child: const Icon(Icons.refresh),
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
                _selectedFiles.clear();
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

  // Ganti method _saveToCloud yang existing dengan ini:
  void _saveToCloud() async {
    final selectedFiles = _selectedFiles
        .map((index) => _userSelectedFiles[index - _defaultFiles.length])
        .toList();
    final selectedDefaultFiles = _selectedDefaultFiles
        .map((index) => _defaultFiles[index])
        .toList();
    final allSelectedFiles = [...selectedFiles, ...selectedDefaultFiles];

    if (allSelectedFiles.isEmpty) return;

    // Ambil email yang akan digunakan (otomatis "CC" jika kosong)
    final cloudEmail = await _firebaseService.getCloudEmail();
    _showCloudSaveConfirmation(allSelectedFiles, cloudEmail);
  }

  void _showCloudSaveConfirmation(
    List<AnimationModel> files,
    String cloudEmail,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkGrey,
        title: Row(
          children: [
            Icon(Icons.cloud_upload, color: AppColors.neonGreen),
            SizedBox(width: 8),
            Text(
              'Save to Cloud',
              style: TextStyle(
                color: AppColors.neonGreen,
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
              'Save ${files.length} file(s) to cloud storage?',
              style: TextStyle(color: AppColors.pureWhite),
            ),
            SizedBox(height: 12),
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
                    'Storage Format:',
                    style: TextStyle(
                      color: AppColors.neonGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '[Channel] [Animation Name] [Email]',
                    style: TextStyle(
                      color: AppColors.pureWhite.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Example: "004 MyAnimation $cloudEmail"',
                    style: TextStyle(
                      color: AppColors.pureWhite.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.email, color: AppColors.neonGreen, size: 16),
                SizedBox(width: 4),
                Text(
                  'Using identifier: $cloudEmail',
                  style: TextStyle(
                    color: AppColors.pureWhite.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (cloudEmail == 'CC') ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 14),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Using "CC" as identifier. Configure device to use your email.',
                        style: TextStyle(color: Colors.blue, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: TextStyle(color: AppColors.neonGreen)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performCloudSave(files);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonGreen,
              foregroundColor: AppColors.primaryBlack,
            ),
            child: Text('SAVE TO CLOUD'),
          ),
        ],
      ),
    );
  }

  Future<void> _performCloudSave(List<AnimationModel> files) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.darkGrey,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.neonGreen),
              SizedBox(height: 16),
              Text(
                'Saving ${files.length} file(s) to cloud...',
                style: TextStyle(color: AppColors.pureWhite),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              FutureBuilder(
                future: _firebaseService.getCloudEmail(),
                builder: (context, snapshot) {
                  final email = snapshot.data ?? 'CC';
                  return Text(
                    'Using identifier: $email',
                    style: TextStyle(
                      color: AppColors.pureWhite.withOpacity(0.7),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ],
          ),
        ),
      );

      // Save files to cloud
      final results = await _firebaseService.saveMultipleAnimationsToCloud(
        files,
      );

      // Close progress dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Analyze results
      final successfulSaves = results.values.where((success) => success).length;
      final failedSaves = results.values.where((success) => !success).length;

      // Show results
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.darkGrey,
          title: Row(
            children: [
              Icon(
                successfulSaves == files.length
                    ? Icons.check_circle
                    : Icons.warning,
                color: successfulSaves == files.length
                    ? AppColors.neonGreen
                    : Colors.orange,
              ),
              SizedBox(width: 8),
              Text(
                'Cloud Save Complete',
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
                'Successfully saved: $successfulSaves/${files.length}',
                style: TextStyle(
                  color: successfulSaves == files.length
                      ? AppColors.neonGreen
                      : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (failedSaves > 0) ...[
                SizedBox(height: 8),
                Text(
                  'Failed: $failedSaves',
                  style: TextStyle(color: Colors.red),
                ),
                SizedBox(height: 12),
                Text(
                  'Failed files:',
                  style: TextStyle(
                    color: AppColors.pureWhite.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                ...results.entries
                    .where((entry) => !entry.value)
                    .map(
                      (entry) => Text(
                        '• ${entry.key}',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
              ],
              SizedBox(height: 12),
              FutureBuilder(
                future: _firebaseService.getCloudEmail(),
                builder: (context, snapshot) {
                  final email = snapshot.data ?? 'CC';
                  return Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlack,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Files stored with format:',
                          style: TextStyle(
                            color: AppColors.pureWhite.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '[Channel] [Name] [$email]',
                          style: TextStyle(
                            color: AppColors.neonGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _selectedFiles.clear();
                  _selectedDefaultFiles.clear();
                  _isLoading = false;
                });

                // Refresh Cloud Files page jika perlu
                _refreshData();
              },
              child: Text('OK', style: TextStyle(color: AppColors.neonGreen)),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close progress dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Error saving to cloud: $e',
            style: TextStyle(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showConfigurationError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkGrey,
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.orange),
            SizedBox(width: 8),
            Text(
              'Device Not Configured',
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
              'Your device needs to be configured before saving to cloud.',
              style: TextStyle(color: AppColors.pureWhite),
            ),
            SizedBox(height: 12),
            Text(
              'Please set up your device configuration with a valid email address.',
              style: TextStyle(
                color: AppColors.pureWhite.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('LATER', style: TextStyle(color: AppColors.neonGreen)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to configuration page
              // Navigator.push(context, MaterialPageRoute(builder: (context) => ConfigurationPage()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonGreen,
              foregroundColor: AppColors.primaryBlack,
            ),
            child: Text('SETUP NOW'),
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
