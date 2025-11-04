// Halaman My File
import 'package:flutter/material.dart';
import 'package:ninexmano_matrix/constants/app_colors.dart';

class MyFilePage extends StatefulWidget {
  const MyFilePage({super.key});

  @override
  State<MyFilePage> createState() => _MyFilePageState();
}

class _MyFilePageState extends State<MyFilePage> {
  // Dummy data untuk file animasi
  final List<AnimationFile> _animationFiles = [
    AnimationFile(
      name: 'Carl Animasi',
      description: 'DENNY AVAIL PROVIDERBY CAR',
      dateCreated: '2024-01-15',
      fileSize: '2.3 MB',
    ),
    AnimationFile(
      name: 'Wave Effect',
      description: 'Smooth wave animation for LED matrix',
      dateCreated: '2024-01-14',
      fileSize: '1.8 MB',
    ),
    AnimationFile(
      name: 'Spiral Rotate',
      description: 'Rotating spiral pattern',
      dateCreated: '2024-01-13',
      fileSize: '3.1 MB',
    ),
    AnimationFile(
      name: 'Text Scroll',
      description: 'Scrolling text display',
      dateCreated: '2024-01-12',
      fileSize: '1.2 MB',
    ),
    AnimationFile(
      name: 'Fire Simulation',
      description: 'Realistic fire animation',
      dateCreated: '2024-01-11',
      fileSize: '4.5 MB',
    ),
    AnimationFile(
      name: 'Rainbow Flow',
      description: 'Flowing rainbow colors',
      dateCreated: '2024-01-10',
      fileSize: '2.7 MB',
    ),
  ];

  // File yang dipilih
  final Set<int> _selectedFiles = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      // appBar: AppBar(
      //   title: const Text('MY FILE'),
      //   backgroundColor: AppColors.darkGrey,
      //   foregroundColor: AppColors.neonGreen,
      //   actions: [
      //     if (_selectedFiles.isNotEmpty)
      //       IconButton(
      //         icon: const Icon(Icons.delete),
      //         onPressed: _deleteSelectedFiles,
      //         tooltip: 'Delete Selected',
      //       ),
      //     if (_selectedFiles.isNotEmpty)
      //       IconButton(
      //         icon: const Icon(Icons.cloud_upload),
      //         onPressed: _saveToCloud,
      //         tooltip: 'Save to Cloud',
      //       ),
      //   ],
      // ),
      body: Column(
        children: [
          // Options Bar (muncul ketika ada file yang dipilih)
          if (_selectedFiles.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppColors.darkGrey,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // DELETE Button
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
                      margin: const EdgeInsets.only(left: 8),
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
          
          // List File Animasi
          Expanded(
            child: ListView.builder(
              itemCount: _animationFiles.length,
              itemBuilder: (context, index) {
                final file = _animationFiles[index];
                final isSelected = _selectedFiles.contains(index);
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.darkGrey,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.neonGreen : AppColors.darkGrey,
                      width: 2,
                    ),
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
                      file.name,
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
                          file.description,
                          style: TextStyle(
                            color: AppColors.pureWhite.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${file.dateCreated} • ${file.fileSize}',
                          style: TextStyle(
                            color: AppColors.pureWhite.withOpacity(0.6),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    trailing: Icon(
                      Icons.animation,
                      color: AppColors.neonGreen,
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
                      // Preview atau action lain ketika long press
                      _previewFile(file);
                    },
                  ),
                );
              },
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
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.neonGreen),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                // Hapus file dari list (dalam urutan descending untuk menghindari index error)
                final sortedIndexes = _selectedFiles.toList()..sort((a, b) => b.compareTo(a));
                for (final index in sortedIndexes) {
                  _animationFiles.removeAt(index);
                }
                _selectedFiles.clear();
              });
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.neonGreen,
                  content: Text(
                    'Files deleted successfully!',
                    style: TextStyle(
                      color: AppColors.primaryBlack,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _saveToCloud() {
    if (_selectedFiles.isEmpty) return;
    
    // Simulasi save to cloud
    final selectedFileNames = _selectedFiles.map((index) => _animationFiles[index].name).toList();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.neonGreen,
        content: Text(
          '${selectedFileNames.length} file(s) saved to cloud!',
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
  }

  void _previewFile(AnimationFile file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkGrey,
        title: Text(
          file.name,
          style: TextStyle(color: AppColors.pureWhite),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description: ${file.description}',
              style: TextStyle(color: AppColors.pureWhite),
            ),
            const SizedBox(height: 8),
            Text(
              'Created: ${file.dateCreated}',
              style: TextStyle(color: AppColors.pureWhite),
            ),
            Text(
              'Size: ${file.fileSize}',
              style: TextStyle(color: AppColors.pureWhite),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: AppColors.neonGreen),
            ),
          ),
        ],
      ),
    );
  }
}

// Model untuk file animasi
class AnimationFile {
  final String name;
  final String description;
  final String dateCreated;
  final String fileSize;

  AnimationFile({
    required this.name,
    required this.description,
    required this.dateCreated,
    required this.fileSize,
  });
}