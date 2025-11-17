// Halaman My File - Updated
import 'package:flutter/material.dart';
import 'package:iTen/constants/app_colors.dart';
import 'package:iTen/models/animation_model.dart';
import 'package:iTen/services/default_animations_service.dart';
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

                  // SAVE TO CLOUD Button
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        left: _selectedFiles.isNotEmpty ? 8 : 0,
                      ),
                      height: 45,
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
                            color: AppColors.neonGreen.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _saveToCloud,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: AppColors.primaryBlack,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'SAVE TO CLOUD',
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

      // Refresh FAB dengan styling
      floatingActionButton: _isLoading
          ? null
          : Container(
              margin: const EdgeInsets.only(bottom: 16, right: 16),
              child: FloatingActionButton(
                onPressed: _refreshData,
                backgroundColor: AppColors.neonGreen,
                foregroundColor: AppColors.primaryBlack,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.refresh, size: 24),
              ),
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
    final results = await _firebaseService.saveMultipleAnimationsToCloud(files);

    // Close progress dialog
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    // Analyze results dengan detail
    final successfulSaves = results.values.where((status) => status == 'success').length;
    final duplicates = results.values.where((status) => status == 'duplicate').length;
    final failures = results.values.where((status) => status == 'failed' || status == 'error').length;

    // Show detailed results
    _showCloudSaveResults(files, results, successfulSaves, duplicates, failures);

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
void _showCloudSaveResults(
  List<AnimationModel> files,
  Map<String, String> results,
  int successfulSaves,
  int duplicates,
  int failures,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.darkGrey,
      title: Row(
        children: [
          Icon(
            successfulSaves > 0 ? Icons.check_circle : Icons.warning,
            color: successfulSaves > 0 ? AppColors.neonGreen : Colors.orange,
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
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary
            Text(
              'Summary:',
              style: TextStyle(
                color: AppColors.neonGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _buildResultItem('✅ Successfully saved:', successfulSaves, Colors.green),
            _buildResultItem('⚠️ Already in cloud:', duplicates, Colors.orange),
            _buildResultItem('❌ Failed to save:', failures, Colors.red),
            
            SizedBox(height: 16),
            
            // Detailed list
            if (duplicates > 0 || failures > 0) ...[
              Text(
                'Details:',
                style: TextStyle(
                  color: AppColors.neonGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              
              // Duplicates
              ...results.entries.where((entry) => entry.value == 'duplicate').map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 16),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${entry.key} (already exists)',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Failures
              ...results.entries.where((entry) => entry.value == 'failed' || entry.value == 'error').map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 16),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${entry.key} (failed)',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
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
            _refreshData();
          },
          child: Text('OK', style: TextStyle(color: AppColors.neonGreen)),
        ),
      ],
    ),
  );
}

Widget _buildResultItem(String label, int count, Color color) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.0),
    child: Row(
      children: [
        Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 12))),
        Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    ),
  );
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
