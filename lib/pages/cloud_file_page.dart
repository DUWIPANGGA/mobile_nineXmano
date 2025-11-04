// Halaman Cloud File
import 'package:flutter/material.dart';
import 'package:ninexmano_matrix/constants/app_colors.dart';

class CloudFilePage extends StatefulWidget {
  const CloudFilePage({super.key});

  @override
  State<CloudFilePage> createState() => _CloudFilePageState();
}

class _CloudFilePageState extends State<CloudFilePage> {
  // Dummy data untuk file animasi cloud
  final List<CloudAnimationFile> _cloudFiles = [
    CloudAnimationFile(
      name: 'Can Animals!',
      description: 'Fun animal animations collection',
      uploadDate: '2024-01-20',
      fileSize: '5.2 MB',
      downloads: 142,
      rating: 4.5,
    ),
    CloudAnimationFile(
      name: 'Neon Patterns',
      description: 'Modern neon light patterns',
      uploadDate: '2024-01-19',
      fileSize: '3.7 MB',
      downloads: 89,
      rating: 4.2,
    ),
    CloudAnimationFile(
      name: 'Cyberpunk City',
      description: 'Cyberpunk style cityscape animations',
      uploadDate: '2024-01-18',
      fileSize: '7.8 MB',
      downloads: 256,
      rating: 4.8,
    ),
    CloudAnimationFile(
      name: 'Nature Flow',
      description: 'Natural flowing water and leaves',
      uploadDate: '2024-01-17',
      fileSize: '4.3 MB',
      downloads: 67,
      rating: 4.0,
    ),
    CloudAnimationFile(
      name: 'Geometric Waves',
      description: 'Mathematical geometric patterns',
      uploadDate: '2024-01-16',
      fileSize: '2.9 MB',
      downloads: 178,
      rating: 4.3,
    ),
  ];

  // File yang dipilih
  final Set<int> _selectedFiles = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: Column(
        children: [

          // Options Bar (muncul ketika ada file yang dipilih)
          if (_selectedFiles.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppColors.darkGrey,
              child: Row(
                children: [
                  // SAVE Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _downloadSelectedFiles,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonGreen,
                        foregroundColor: AppColors.primaryBlack,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'SAVE',
                            style: TextStyle(
                              fontSize: 16,
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

          // Separator Line
          Container(
            height: 1,
            color: AppColors.neonGreen.withOpacity(0.3),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),

          // List File Animasi Cloud
          Expanded(
            child: ListView.builder(
              itemCount: _cloudFiles.length,
              itemBuilder: (context, index) {
                final file = _cloudFiles[index];
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
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.download, size: 12, color: AppColors.neonGreen),
                            const SizedBox(width: 4),
                            Text(
                              '${file.downloads}',
                              style: TextStyle(
                                color: AppColors.pureWhite.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.star, size: 12, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '${file.rating}',
                              style: TextStyle(
                                color: AppColors.pureWhite.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${file.fileSize}',
                              style: TextStyle(
                                color: AppColors.pureWhite.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          file.uploadDate,
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
                      _previewCloudFile(file);
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

  void _downloadSelectedFiles() {
    if (_selectedFiles.isEmpty) return;
    
    // Simulasi download file
    final selectedFileNames = _selectedFiles.map((index) => _cloudFiles[index].name).toList();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.neonGreen,
        content: Text(
          'Downloading ${selectedFileNames.length} file(s)...',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.neonGreen,
          content: Text(
            '${selectedFileNames.length} file(s) downloaded successfully!',
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

  void _previewCloudFile(CloudAnimationFile file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkGrey,
        title: Text(
          file.name,
          style: TextStyle(color: AppColors.neonGreen),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description: ${file.description}',
                style: TextStyle(color: AppColors.pureWhite),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.download, size: 16, color: AppColors.neonGreen),
                  const SizedBox(width: 6),
                  Text(
                    'Downloads: ${file.downloads}',
                    style: TextStyle(color: AppColors.pureWhite),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 6),
                  Text(
                    'Rating: ${file.rating}/5.0',
                    style: TextStyle(color: AppColors.pureWhite),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'File Size: ${file.fileSize}',
                style: TextStyle(color: AppColors.pureWhite),
              ),
              const SizedBox(height: 6),
              Text(
                'Uploaded: ${file.uploadDate}',
                style: TextStyle(color: AppColors.pureWhite),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: AppColors.neonGreen),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadFile(file);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonGreen,
              foregroundColor: AppColors.primaryBlack,
            ),
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  void _downloadFile(CloudAnimationFile file) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.neonGreen,
        content: Text(
          'Downloading ${file.name}...',
          style: TextStyle(
            color: AppColors.primaryBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// Model untuk file animasi cloud
class CloudAnimationFile {
  final String name;
  final String description;
  final String uploadDate;
  final String fileSize;
  final int downloads;
  final double rating;

  CloudAnimationFile({
    required this.name,
    required this.description,
    required this.uploadDate,
    required this.fileSize,
    required this.downloads,
    required this.rating,
  });
}