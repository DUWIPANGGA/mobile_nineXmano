// Halaman Mapping
import 'package:flutter/material.dart';
import 'package:ninexmano_matrix/constants/app_colors.dart';
import 'package:ninexmano_matrix/models/animation_model.dart';
import 'package:ninexmano_matrix/services/firebase_data_service.dart';

class MappingPage extends StatefulWidget {
  const MappingPage({super.key});

  @override
  State<MappingPage> createState() => _MappingPageState();
}

class _MappingPageState extends State<MappingPage> {
  final FirebaseDataService _firebaseService = FirebaseDataService();
  
  // Dropdown values untuk setiap tombol
  String? _selectedAnimationA;
  String? _selectedAnimationB;
  String? _selectedAnimationC;
  String? _selectedAnimationD;

  // Data dari preferences
  List<AnimationModel> _userAnimations = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserAnimations();
    _loadSavedMappings();
  }

  // Load animasi dari user selections di preferences
  Future<void> _loadUserAnimations() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final userAnimations = await _firebaseService.getUserSelectedAnimations();
      
      setState(() {
        _userAnimations = userAnimations;
        _isLoading = false;
      });

      print('✅ Loaded ${_userAnimations.length} animations for mapping');

    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading animations: $e';
        _isLoading = false;
      });
      print('❌ Error loading animations for mapping: $e');
    }
  }

  // Load saved mappings dari preferences
  Future<void> _loadSavedMappings() async {
    try {
      final mappings = await _firebaseService.getUserSetting('button_mappings') as Map<String, dynamic>?;
      
      if (mappings != null) {
        setState(() {
          _selectedAnimationA = mappings['button_a'];
          _selectedAnimationB = mappings['button_b'];
          _selectedAnimationC = mappings['button_c'];
          _selectedAnimationD = mappings['button_d'];
        });
        
        print('✅ Loaded saved mappings from preferences');
      }
    } catch (e) {
      print('❌ Error loading saved mappings: $e');
    }
  }

  // Save mappings ke preferences
  Future<void> _saveMappings() async {
    try {
      final mappings = {
        'button_a': _selectedAnimationA,
        'button_b': _selectedAnimationB,
        'button_c': _selectedAnimationC,
        'button_d': _selectedAnimationD,
        'last_updated': DateTime.now().toIso8601String(),
      };
      
      await _firebaseService.saveUserSetting('button_mappings', mappings);
      print('💾 Saved mappings to preferences');
    } catch (e) {
      print('❌ Error saving mappings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
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
                    const SizedBox(height: 8),
                    
                    // Statistics
                    Text(
                      '${_userAnimations.length} animations available',
                      style: TextStyle(
                        color: AppColors.pureWhite.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Loading Indicator
                    if (_isLoading)
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: AppColors.neonGreen),
                            SizedBox(height: 8),
                            Text(
                              'Loading animations...',
                              style: TextStyle(color: AppColors.pureWhite),
                            ),
                          ],
                        ),
                      )
                    
                    // Error Message
                    else if (_errorMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                            IconButton(
                              onPressed: _loadUserAnimations,
                              icon: Icon(Icons.refresh, color: Colors.red),
                              iconSize: 20,
                            ),
                          ],
                        ),
                      )
                    
                    // Empty State
                    else if (_userAnimations.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlack,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.animation_outlined,
                              color: AppColors.pureWhite.withOpacity(0.5),
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No animations found',
                              style: TextStyle(
                                color: AppColors.pureWhite.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Download animations from Cloud Files first',
                              style: TextStyle(
                                color: AppColors.pureWhite.withOpacity(0.5),
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    
                    // Mapping Items
                    else ...[
                      // Setting Tombol A
                      _buildMappingItem(
                        label: 'TOMBOL A :',
                        selectedValue: _selectedAnimationA,
                        onChanged: (value) {
                          setState(() {
                            _selectedAnimationA = value;
                          });
                          _saveMappings();
                        },
                      ),
                      
                      // Setting Tombol B
                      _buildMappingItem(
                        label: 'TOMBOL B :',
                        selectedValue: _selectedAnimationB,
                        onChanged: (value) {
                          setState(() {
                            _selectedAnimationB = value;
                          });
                          _saveMappings();
                        },
                      ),
                      
                      // Setting Tombol C
                      _buildMappingItem(
                        label: 'TOMBOL C :',
                        selectedValue: _selectedAnimationC,
                        onChanged: (value) {
                          setState(() {
                            _selectedAnimationC = value;
                          });
                          _saveMappings();
                        },
                      ),
                      
                      // Setting Tombol D
                      _buildMappingItem(
                        label: 'TOMBOL D :',
                        selectedValue: _selectedAnimationD,
                        onChanged: (value) {
                          setState(() {
                            _selectedAnimationD = value;
                          });
                          _saveMappings();
                        },
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Tombol KIRIM SEMUA
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _userAnimations.isEmpty ? null : _sendAllAnimations,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _userAnimations.isEmpty 
                        ? AppColors.neonGreen.withOpacity(0.3)
                        : AppColors.neonGreen,
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
          
              // Info Panel
              if (_userAnimations.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.darkGrey,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mapping Summary',
                        style: TextStyle(
                          color: AppColors.neonGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildMappingInfo('Button A', _selectedAnimationA),
                      _buildMappingInfo('Button B', _selectedAnimationB),
                      _buildMappingInfo('Button C', _selectedAnimationC),
                      _buildMappingInfo('Button D', _selectedAnimationD),
                    ],
                  ),
                ),
              ],
            ],
          ),
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
                hint: Text(
                  'Pilih Animasi',
                  style: TextStyle(
                    color: AppColors.pureWhite.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                items: _buildDropdownItems(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildDropdownItems() {
    // Item untuk clear selection
    final items = <DropdownMenuItem<String>>[
      DropdownMenuItem<String>(
        value: null,
        child: Text(
          'Tidak ada animasi',
          style: TextStyle(
            color: AppColors.pureWhite.withOpacity(0.5),
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    ];

    // Add all user animations
    items.addAll(_userAnimations.map((animation) {
      return DropdownMenuItem<String>(
        value: animation.name,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              animation.name,
              style: TextStyle(
                color: AppColors.pureWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${animation.channelCount}C • ${animation.animationLength}L • ${animation.totalFrames}F',
              style: TextStyle(
                color: AppColors.pureWhite.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }).toList());

    return items;
  }

  Widget _buildMappingInfo(String buttonName, String? animationName) {
    final animation = _userAnimations.firstWhere(
      (anim) => anim.name == animationName,
      orElse: () => AnimationModel(
        name: '',
        channelCount: 0,
        animationLength: 0,
        description: '',
        delayData: '',
        frameData: [],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$buttonName:',
              style: TextStyle(
                color: AppColors.pureWhite.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ),
          if (animationName != null && animation.name.isNotEmpty)
            Expanded(
              child: Row(
                children: [
                  Text(
                    animationName,
                    style: TextStyle(
                      color: AppColors.neonGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${animation.channelCount}C',
                      style: TextStyle(
                        color: AppColors.neonGreen,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${animation.animationLength}L',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              'Not assigned',
              style: TextStyle(
                color: AppColors.pureWhite.withOpacity(0.5),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  void _sendAllAnimations() {
    if (_userAnimations.isEmpty) return;

    // Validasi minimal satu animasi dipilih
    final selectedAnimations = [
      _selectedAnimationA,
      _selectedAnimationB,
      _selectedAnimationC,
      _selectedAnimationD,
    ].where((anim) => anim != null).toList();

    if (selectedAnimations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange,
          content: const Text(
            'Pilih minimal satu animasi terlebih dahulu!',
            style: TextStyle(
              color: AppColors.primaryBlack,
              fontWeight: FontWeight.bold,
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Logic untuk mengirim semua animasi yang dipilih
    print('🔄 Mengirim animasi mapping:');
    print('   Tombol A: $_selectedAnimationA');
    print('   Tombol B: $_selectedAnimationB');
    print('   Tombol C: $_selectedAnimationC');
    print('   Tombol D: $_selectedAnimationD');

    // Simpan mapping terakhir yang dikirim
    _firebaseService.saveUserSetting('last_sent_mappings', {
      'button_a': _selectedAnimationA,
      'button_b': _selectedAnimationB,
      'button_c': _selectedAnimationC,
      'button_d': _selectedAnimationD,
      'sent_at': DateTime.now().toIso8601String(),
    });

    // Tampilkan snackbar konfirmasi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.neonGreen,
        content: Text(
          '${selectedAnimations.length} animasi berhasil dikirim!',
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