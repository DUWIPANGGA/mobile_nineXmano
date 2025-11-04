// Halaman Trigger
import 'package:flutter/material.dart';
import 'package:ninexmano_matrix/constants/app_colors.dart';

class TriggerPage extends StatefulWidget {
  const TriggerPage({super.key});

  @override
  State<TriggerPage> createState() => _TriggerPageState();
}

class _TriggerPageState extends State<TriggerPage> {
  // Dropdown values untuk setiap trigger
  String? _selectedQuick;
  String? _selectedLowBeam;
  String? _selectedHighBeam;
  String? _selectedFogLamp;

  // List opsi yang tersedia
  final List<String> _triggerOptions = [
    'MATI',
    'MAP STATIS',
    'MAP DINAMIS',
    'ANIMASI WAVE',
    'ANIMASI SPIRAL',
    'ANIMASI TEXT',
    'ANIMASI CUSTOM',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Container untuk 4 settingan trigger
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
                      'Trigger Settings',
                      style: TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Setting QUICK
                    _buildTriggerItem(
                      label: 'QUICK',
                      selectedValue: _selectedQuick,
                      onChanged: (value) {
                        setState(() {
                          _selectedQuick = value;
                        });
                      },
                    ),
                    
                    // Setting LOW BEAM
                    _buildTriggerItem(
                      label: 'LOW BEAM',
                      selectedValue: _selectedLowBeam,
                      onChanged: (value) {
                        setState(() {
                          _selectedLowBeam = value;
                        });
                      },
                    ),
                    
                    // Setting HIGH BEAM
                    _buildTriggerItem(
                      label: 'HIGH BEAM',
                      selectedValue: _selectedHighBeam,
                      onChanged: (value) {
                        setState(() {
                          _selectedHighBeam = value;
                        });
                      },
                    ),
                    
                    // Setting FOG LAMP
                    _buildTriggerItem(
                      label: 'FOG LAMP',
                      selectedValue: _selectedFogLamp,
                      onChanged: (value) {
                        setState(() {
                          _selectedFogLamp = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Tombol SIMPAN SETTING
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    _saveTriggerSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGreen,
                    foregroundColor: AppColors.primaryBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'SIMPAN SETTING',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          
              const SizedBox(height: 16),
          
              // Tombol RESET
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    _resetTriggerSettings();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.neonGreen,
                    side: BorderSide(color: AppColors.neonGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'RESET',
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
      ),
    );
  }

  Widget _buildTriggerItem({
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
          // Label trigger
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.pureWhite,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(width: 10),
          
          // Dropdown opsi trigger
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
                  'Pilih Mode',
                  style: TextStyle(
                    color: AppColors.pureWhite.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                items: _triggerOptions.map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(
                      option,
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

  void _saveTriggerSettings() {
    // Logic untuk menyimpan setting trigger
    print('Menyimpan trigger settings:');
    print('QUICK: $_selectedQuick');
    print('LOW BEAM: $_selectedLowBeam');
    print('HIGH BEAM: $_selectedHighBeam');
    print('FOG LAMP: $_selectedFogLamp');
    
    // Tampilkan snackbar konfirmasi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.neonGreen,
        content: Text(
          'Trigger settings berhasil disimpan!',
          style: TextStyle(
            color: AppColors.primaryBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _resetTriggerSettings() {
    setState(() {
      _selectedQuick = null;
      _selectedLowBeam = null;
      _selectedHighBeam = null;
      _selectedFogLamp = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.neonGreen,
        content: Text(
          'Trigger settings telah direset!',
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