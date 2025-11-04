// Halaman Mapping
import 'package:flutter/material.dart';
import 'package:ninexmano_matrix/constants/app_colors.dart';

class MappingPage extends StatefulWidget {
  const MappingPage({super.key});

  @override
  State<MappingPage> createState() => _MappingPageState();
}

class _MappingPageState extends State<MappingPage> {
  // Dropdown values untuk setiap tombol
  String? _selectedAnimationA;
  String? _selectedAnimationB;
  String? _selectedAnimationC;
  String? _selectedAnimationD;

  // List animasi yang tersedia
  final List<String> _animations = [
    'Wave',
    'Spiral',
    'Text Scroll',
    'Pulse',
    'Rainbow',
    'Fire',
    'Matrix',
    'Custom 1',
    'Custom 2',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Container untuk 4 settingan
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
                  const Text(
                    'Animation Mapping',
                    style: TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Setting Tombol A
                  _buildMappingItem(
                    label: 'TOMBOL A : MaNo 04 || X L...',
                    selectedValue: _selectedAnimationA,
                    onChanged: (value) {
                      setState(() {
                        _selectedAnimationA = value;
                      });
                    },
                  ),
                  
                  // Setting Tombol B
                  _buildMappingItem(
                    label: 'TOMBOL B : MaNo 01 || AU...',
                    selectedValue: _selectedAnimationB,
                    onChanged: (value) {
                      setState(() {
                        _selectedAnimationB = value;
                      });
                    },
                  ),
                  
                  // Setting Tombol C
                  _buildMappingItem(
                    label: 'TOMBOL C : MaNo 01 || AU...',
                    selectedValue: _selectedAnimationC,
                    onChanged: (value) {
                      setState(() {
                        _selectedAnimationC = value;
                      });
                    },
                  ),
                  
                  // Setting Tombol D
                  _buildMappingItem(
                    label: 'TOMBOL D : MaNo 01 || AU...',
                    selectedValue: _selectedAnimationD,
                    onChanged: (value) {
                      setState(() {
                        _selectedAnimationD = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Tombol KIRIM SEMUA
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  _sendAllAnimations();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonGreen,
                  foregroundColor: AppColors.primaryBlack,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'KIRIM SEMUA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMappingItem({
    required String label,
    required String? selectedValue,
    required Function(String?) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // Label tombol
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.pureWhite,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(width: 10),
          
          // Dropdown animasi
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.darkGrey,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.neonGreen),
              ),
              child: DropdownButton<String>(
                value: selectedValue,
                isExpanded: true,
                dropdownColor: AppColors.darkGrey,
                style: const TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 14,
                ),
                underline: const SizedBox(), // Remove default underline
                icon: Icon(Icons.arrow_drop_down, color: AppColors.neonGreen),
                hint: const Text(
                  'Pilih Animasi',
                  style: TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 14,
                  ),
                ),
                items: _animations.map((String animation) {
                  return DropdownMenuItem<String>(
                    value: animation,
                    child: Text(
                      animation,
                      style: const TextStyle(
                        color: AppColors.pureWhite,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendAllAnimations() {
    // Logic untuk mengirim semua animasi yang dipilih
    print('Mengirim animasi:');
    print('Tombol A: $_selectedAnimationA');
    print('Tombol B: $_selectedAnimationB');
    print('Tombol C: $_selectedAnimationC');
    print('Tombol D: $_selectedAnimationD');
    
    // Tampilkan snackbar konfirmasi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.neonGreen,
        content: Text(
          'Animasi berhasil dikirim!',
          style: TextStyle(
            color: AppColors.primaryBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}