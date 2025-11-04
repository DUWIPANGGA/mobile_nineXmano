// pages/database_viewer_page.dart
import 'package:flutter/material.dart';
import 'package:ninexmano_matrix/constants/app_colors.dart';
import 'package:ninexmano_matrix/models/animation_model.dart';
import 'package:ninexmano_matrix/models/list_animation_model.dart';
import 'package:ninexmano_matrix/models/system_model.dart';
import 'package:ninexmano_matrix/services/firebase_data_service.dart';

class DatabaseViewerPage extends StatefulWidget {
  const DatabaseViewerPage({super.key});

  @override
  State<DatabaseViewerPage> createState() => _DatabaseViewerPageState();
}

class _DatabaseViewerPageState extends State<DatabaseViewerPage> {
  final FirebaseDataService _firebaseService = FirebaseDataService();
  
  // Data states
  ListAnimationModel _userAnimations = ListAnimationModel.empty('USER');
  SystemModel? _systemData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Load data dari kedua node
      final userAnimations = await _firebaseService.getUserAnimations();
      final systemData = await _firebaseService.getSystemModel();

      setState(() {
        _userAnimations = userAnimations;
        _systemData = systemData;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  void _refreshData() {
    _loadAllData();
  }

  void _showAnimationDetails(AnimationModel animation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkGrey,
        title: Text(
          animation.name,
          style: const TextStyle(
            color: AppColors.neonGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Channel Count', animation.channelCount.toString()),
              _buildDetailRow('Animation Length', animation.animationLength.toString()),
              _buildDetailRow('Total Frames', animation.totalFrames.toString()),
              _buildDetailRow('Description', animation.description.isEmpty ? '(empty)' : animation.description),
              _buildDetailRow('Delay Data', animation.delayData),
              const SizedBox(height: 16),
              const Text(
                'Frame Data:',
                style: TextStyle(
                  color: AppColors.neonGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ...animation.frameData.take(5).map((frame) => 
                Text(
                  frame,
                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 10,
                    fontFamily: 'Monospace',
                  ),
                )
              ),
              if (animation.frameData.length > 5)
                Text(
                  '... and ${animation.frameData.length - 5} more frames',
                  style: TextStyle(
                    color: AppColors.pureWhite.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CLOSE',
              style: TextStyle(color: AppColors.neonGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: AppColors.pureWhite.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.pureWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSystemDetails(SystemModel system) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkGrey,
        title: const Text(
          'System Configuration',
          style: TextStyle(
            color: AppColors.neonGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Module Info', system.info),
              _buildDetailRow('Version', system.version),
              _buildDetailRow('Version 2', system.version2),
              _buildDetailRow('Description', system.deskripsi.isEmpty ? '(empty)' : system.deskripsi),
              _buildDetailRow('Description 2', system.deskripsi2.isEmpty ? '(empty)' : system.deskripsi2),
              _buildDetailRow('Link', system.link.isEmpty ? '(empty)' : system.link),
              _buildDetailRow('Link 2', system.link2.isEmpty ? '(empty)' : system.link2),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CLOSE',
              style: TextStyle(color: AppColors.neonGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimationList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Statistics Card
        Card(
          color: AppColors.darkGrey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'USER ANIMATIONS',
                  style: TextStyle(
                    color: AppColors.neonGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _userAnimations.summary,
                  style: const TextStyle(color: AppColors.pureWhite),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  children: [
                    _buildStatItem('Total', _userAnimations.length.toString()),
                    _buildStatItem('Valid', _userAnimations.validCount.toString()),
                    _buildStatItem('Frames', _userAnimations.totalFrames.toString()),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Animation List
        Expanded(
          child: _userAnimations.isEmpty
              ? const Center(
                  child: Text(
                    'No animations found in USER node',
                    style: TextStyle(color: AppColors.pureWhite),
                  ),
                )
              : ListView.builder(
                  itemCount: _userAnimations.length,
                  itemBuilder: (context, index) {
                    final animation = _userAnimations[index];
                    return Card(
                      color: AppColors.darkGrey,
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.neonGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${animation.channelCount}C',
                            style: const TextStyle(
                              color: AppColors.neonGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          animation.name,
                          style: const TextStyle(
                            color: AppColors.pureWhite,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Length: ${animation.animationLength} | Frames: ${animation.totalFrames}',
                          style: TextStyle(
                            color: AppColors.pureWhite.withOpacity(0.7),
                          ),
                        ),
                        trailing: Icon(
                          animation.isValid ? Icons.check_circle : Icons.error,
                          color: animation.isValid ? AppColors.neonGreen : Colors.red,
                        ),
                        onTap: () => _showAnimationDetails(animation),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSystemCard() {
    if (_systemData == null) {
      return const Card(
        color: AppColors.darkGrey,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No system data found',
            style: TextStyle(color: AppColors.pureWhite),
          ),
        ),
      );
    }

    return Card(
      color: AppColors.darkGrey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SYSTEM CONFIGURATION',
              style: TextStyle(
                color: AppColors.neonGreen,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _buildSystemInfoRow('Module Info', _systemData!.info),
            _buildSystemInfoRow('Version', _systemData!.version),
            _buildSystemInfoRow('Secondary Version', _systemData!.version2),
            _buildSystemInfoRow('Description', _systemData!.deskripsi),
            _buildSystemInfoRow('Secondary Description', _systemData!.deskripsi2),
            _buildSystemInfoRow('Link', _systemData!.link),
            _buildSystemInfoRow('Secondary Link', _systemData!.link2),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton(
                onPressed: () => _showSystemDetails(_systemData!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonGreen,
                  foregroundColor: AppColors.primaryBlack,
                ),
                child: const Text('VIEW DETAILED SYSTEM INFO'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                color: AppColors.pureWhite.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: AppColors.pureWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.neonGreen,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.pureWhite.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: AppBar(
        title: const Text(
          'DATABASE VIEWER',
          style: TextStyle(
            color: AppColors.neonGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.darkGrey,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.neonGreen),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.neonGreen),
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.neonGreen),
                  SizedBox(height: 16),
                  Text(
                    'Loading database...',
                    style: TextStyle(color: AppColors.pureWhite),
                  ),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 64,
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
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // System Card
                      _buildSystemCard(),
                      const SizedBox(height: 20),
                      // Animations Section
                      const Text(
                        'USER ANIMATIONS',
                        style: TextStyle(
                          color: AppColors.neonGreen,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _buildAnimationList(),
                      ),
                    ],
                  ),
                ),
    );
  }
}