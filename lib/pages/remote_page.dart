import 'package:flutter/material.dart';
import 'package:ninexmano_matrix/constants/app_colors.dart';

class RemotePage extends StatefulWidget {
  const RemotePage({super.key});

  @override
  State<RemotePage> createState() => _RemotePageState();
}

class _RemotePageState extends State<RemotePage> {
  // State untuk tombol Auto ABCD
  final Map<String, bool> _autoButtonsState = {
    'A': false,
    'B': false,
    'C': false,
    'D': false,
  };

  void _showMoreModal(BuildContext context) {
  showModalBottomSheet(
    isScrollControlled: true,
    context: context,
    backgroundColor: AppColors.darkGrey,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header KEMBALI
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBlack,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.neonGreen),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '# KEMBALI',
                    style: TextStyle(
                      color: AppColors.neonGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.arrow_upward, color: AppColors.neonGreen),
                ],
              ),
            ),
            
            
            const SizedBox(height: 20),
            
            // Grid untuk tombol R dengan angka 3-31
            SizedBox(
              height: MediaQuery.of(context).size.height,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // 4 kolom
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: 30, // R + 3 sampai 31 = 1 + 29 = 30 item
                itemBuilder: (context, index) {
                  // Mapping index ke label
                  String label;
                  if (index == 0) {
                    label = 'R'; // Index 0 adalah R
                  } else {
                    label = (index + 2).toString(); // 3 sampai 31
                  }
                  
                  return _buildNumberButton(label);
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

  Widget _buildModalButton(String title, String subtitle) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neonGreen),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.neonGreen,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.pureWhite.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNumberButton(String label) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neonGreen),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.pureWhite,
            fontSize: label == 'R' || label == 'n' ? 14 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _toggleAutoButton(String label) {
    setState(() {
      _autoButtonsState[label] = !_autoButtonsState[label]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Container untuk tombol Auto ABCD
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkGrey,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.neonGreen),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                const SizedBox(height: 16),
                _buildAutoButton('Auto ABCD'),
                _buildAutoButton('A'),
                _buildAutoButton('B'),
                _buildAutoButton('C'),
                _buildAutoButton('D'),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Menu More dan Mic
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Menu More
              Expanded(
                child: GestureDetector(
                  onTap: () => _showMoreModal(context),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.darkGrey,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.neonGreen),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.more_horiz, color: AppColors.neonGreen),
                        const SizedBox(width: 8),
                        Text(
                          'More',
                          style: TextStyle(
                            color: AppColors.neonGreen,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Mic
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.darkGrey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.neonGreen),
                ),
                child: IconButton(
                  icon: Icon(Icons.mic, color: AppColors.neonGreen),
                  onPressed: () {
                    // Mic functionality
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAutoButton(String label) {
    final isActive = _autoButtonsState[label] ?? false;
    
    return GestureDetector(
      onTap: () => _toggleAutoButton(label),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.neonGreen : AppColors.primaryBlack,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.neonGreen,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primaryBlack : AppColors.pureWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(
              isActive ? Icons.pause : Icons.play_arrow,
              color: isActive ? AppColors.primaryBlack : AppColors.neonGreen,
            ),
          ],
        ),
      ),
    );
  }
}