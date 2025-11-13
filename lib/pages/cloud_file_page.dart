// Halaman Cloud File
import 'package:flutter/material.dart';
import 'package:iTen/constants/app_colors.dart';
import 'package:iTen/models/animation_model.dart';
import 'package:iTen/models/list_animation_model.dart';
import 'package:iTen/services/firebase_data_service.dart';

class CloudFilePage extends StatefulWidget {
  const CloudFilePage({super.key});

  @override
  State<CloudFilePage> createState() => _CloudFilePageState();
}

class _CloudFilePageState extends State<CloudFilePage> {
  final FirebaseDataService _firebaseService = FirebaseDataService();
  final Set<int> _selectedFiles = {};
  
  // Data dari preferences
  ListAnimationModel _userAnimations = ListAnimationModel.empty('USER');
    ListAnimationModel _filteredAnimations = ListAnimationModel.empty('FILTERED');
  int _channelFilter = 016; // Filter channel count 16
  int _startIndex = 1; // Mulai dari index 2
  int _endIndex = 3;   // Sampai index 3
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAnimationsFromPreferences();
  }

  ListAnimationModel _applyFilters(ListAnimationModel animations) {
  final filteredList = <AnimationModel>[];
  
  for (int i = 0; i < animations.length; i++) {
    // Filter berdasarkan index range (pastikan index valid)
    // if (i >= _startIndex - 1 && i <= _endIndex - 1 && i < animations.length) {
      final animation = animations[i];
        print(
          "${animation.channelCount} == $_channelFilter"
        );
      
      // Filter berdasarkan channel count
      if (animation.channelCount == _channelFilter) {
        filteredList.add(animation);
      }
    // }
  }
  
  return ListAnimationModel.fromList(
    filteredList, 
    'Filtered (Index $_startIndex-$_endIndex, Channel $_channelFilter)'
  );
}
  // Load data dari preferences
  // Load data dari preferences
Future<void> _loadAnimationsFromPreferences() async {
  try {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final animations = await _firebaseService.getUserAnimationsWithCache();
    final filtered = _applyFilters(animations); // Apply filter

    setState(() {
      _userAnimations = animations;
      _filteredAnimations = filtered; // Tambahkan ini
      _isLoading = false;
    });

    print('✅ Loaded ${_userAnimations.length} animations from preferences');
    print('✅ Filtered to ${_filteredAnimations.length} animations');

  } catch (e) {
    setState(() {
      _errorMessage = 'Error loading animations: $e';
      _isLoading = false;
    });
    print('❌ Error loading animations from preferences: $e');
  }
}

  Future<void> _refreshData() async {
  try {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Force refresh dari Firebase
    await _firebaseService.forceRefreshApiData();
    
    // Load ulang dari preferences
    final animations = await _firebaseService.getUserAnimationsWithCache();
    final filtered = _applyFilters(animations);

    setState(() {
      _userAnimations = animations;
      _filteredAnimations = filtered; // Update filtered data
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.neonGreen,
        content: const Text(
          'Data refreshed from cloud!',
          style: TextStyle(
            color: AppColors.primaryBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );

  } catch (e) {
    setState(() {
      _errorMessage = 'Error refreshing data: $e';
      _isLoading = false;
    });
    print('❌ Error refreshing data: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: Column(
        children: [
          // App Bar Custom dengan refresh button
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.darkGrey,
            child: Row(
              children: [
                // Title
                Text(
                  'CLOUD ANIMATIONS',
                  style: TextStyle(
                    color: AppColors.neonGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                
                // Refresh Button
                IconButton(
                  onPressed: _isLoading ? null : _refreshData,
                  icon: Icon(
                    Icons.refresh,
                    color: _isLoading ? AppColors.pureWhite.withOpacity(0.5) : AppColors.neonGreen,
                  ),
                  tooltip: 'Refresh from cloud',
                ),
                
                // Statistics
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlack,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.neonGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${_filteredAnimations.length} files',
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
          if (_selectedFiles.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppColors.darkGrey,
              child: Row(
                children: [
                  // Selected count
                  Text(
                    '${_selectedFiles.length} selected',
                    style: TextStyle(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  
                  // SAVE Button
                  ElevatedButton(
                    onPressed: _downloadSelectedFiles,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonGreen,
                      foregroundColor: AppColors.primaryBlack,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.download, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'SAVE TO DEVICE',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Separator Line
          Container(
            height: 1,
            color: AppColors.neonGreen.withOpacity(0.3),
          ),

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
                      'Loading cloud animations...',
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
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
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
          else if (_filteredAnimations.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off,
                      color: AppColors.pureWhite.withOpacity(0.5),
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No cloud animations found',
                      style: TextStyle(
                        color: AppColors.pureWhite.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pull down to refresh or check your connection',
                      style: TextStyle(
                        color: AppColors.pureWhite.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )

          // List File Animasi Cloud
          else
            Expanded(
              child: ListView.builder(
                itemCount: _filteredAnimations.length,
                itemBuilder: (context, index) {
                  final animation = _filteredAnimations[index];
                  final isSelected = _selectedFiles.contains(index);
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.darkGrey,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.neonGreen : Colors.transparent,
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
                      leading: Checkbox(
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
                        fillColor: MaterialStateProperty.all(AppColors.neonGreen),
                      ),
                      title: Text(
                        animation.name,
                        style: TextStyle(
                          color: AppColors.pureWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            animation.description.isEmpty ? 'No description' : animation.description,
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
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.neonGreen.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${animation.channelCount}C',
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
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${animation.animationLength}L',
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
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${animation.totalFrames}F',
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
                                animation.isValid ? Icons.check_circle : Icons.error,
                                color: animation.isValid ? AppColors.neonGreen : Colors.red,
                                size: 16,
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Last Sync info (jika ada)
                          if (_filteredAnimations.lastSync != null)
                            Text(
                              _formatDate(_filteredAnimations.lastSync),
                              style: TextStyle(
                                color: AppColors.pureWhite.withOpacity(0.6),
                                fontSize: 10,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Icon(
                            Icons.cloud,
                            color: AppColors.neonGreen,
                            size: 20,
                          ),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          if (_selectedFiles.contains(index)) {
                            _selectedFiles.remove(index);
                          } else {
                            _selectedFiles.add(index);
                          }
                        });
                      },
                      onLongPress: () {
                        _previewCloudFile(animation);
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),

      // Refresh indicator
      floatingActionButton: _isLoading ? null : FloatingActionButton(
        onPressed: _refreshData,
        backgroundColor: AppColors.neonGreen,
        foregroundColor: AppColors.primaryBlack,
        mini: true,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  // Format date untuk display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _downloadSelectedFiles() {
    if (_selectedFiles.isEmpty) return;
    
    // Simulasi download file
    final selectedAnimations = _selectedFiles.map((index) => _filteredAnimations[index]).toList();
    final selectedNames = selectedAnimations.map((anim) => anim.name).toList();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.neonGreen,
        content: Text(
          'Downloading ${selectedNames.length} animation(s)...',
          style: TextStyle(
            color: AppColors.primaryBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // Simulasi proses download
    Future.delayed(const Duration(seconds: 2), () {
      // Simpan sebagai user selected animations
      for (final animation in selectedAnimations) {
        _firebaseService.addToUserSelections(animation);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.neonGreen,
          content: Text(
            '${selectedNames.length} animation(s) saved to device!',
            style: TextStyle(
              color: AppColors.primaryBlack,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
      
      setState(() {
        _selectedFiles.clear();
      });
    });
  }

  void _previewCloudFile(AnimationModel animation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkGrey,
        title: Text(
          animation.name,
          style: TextStyle(
            color: AppColors.neonGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description
              Text(
                'Description: ${animation.description.isEmpty ? "No description" : animation.description}',
                style: TextStyle(color: AppColors.pureWhite),
              ),
              const SizedBox(height: 12),
              
              // Technical Details
              _buildDetailRow('Channel Count', '${animation.channelCount}'),
              _buildDetailRow('Animation Length', '${animation.animationLength}'),
              _buildDetailRow('Total Frames', '${animation.totalFrames}'),
              _buildDetailRow('Delay Data', animation.delayData),
              _buildDetailRow('Validation', animation.isValid ? 'Valid' : 'Invalid'),
              
              const SizedBox(height: 12),
              
              // Frame Data Preview
              if (animation.frameData.isNotEmpty) ...[
                Text(
                  'Frame Data Preview:',
                  style: TextStyle(
                    color: AppColors.neonGreen,
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
                    animation.frameData.take(3).join('\n'),
                    style: TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 10,
                      fontFamily: 'Monospace',
                    ),
                    maxLines: 6,
                  ),
                ),
                if (animation.frameData.length > 3)
                  Text(
                    '... and ${animation.frameData.length - 3} more frames',
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
            child: Text(
              'CLOSE',
              style: TextStyle(color: AppColors.neonGreen),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadSingleFile(animation);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonGreen,
              foregroundColor: AppColors.primaryBlack,
            ),
            child: const Text('DOWNLOAD'),
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
              style: TextStyle(
                color: AppColors.pureWhite.withOpacity(0.7),
              ),
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

  void _downloadSingleFile(AnimationModel animation) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.neonGreen,
        content: Text(
          'Downloading ${animation.name}...',
          style: TextStyle(
            color: AppColors.primaryBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
    
    // Simpan sebagai user selected animation
    _firebaseService.addToUserSelections(animation);
    
    Future.delayed(const Duration(seconds: 1), () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.neonGreen,
          content: Text(
            '${animation.name} saved to device!',
            style: TextStyle(
              color: AppColors.primaryBlack,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    });
  }
}