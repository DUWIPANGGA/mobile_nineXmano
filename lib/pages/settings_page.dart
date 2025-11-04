import 'package:flutter/material.dart';
import 'package:ninexmano_matrix/constants/app_colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _welcomeModeEnabled = true;
  String _selectedSpeed = 'SEDANG';
  final TextEditingController _emailController = TextEditingController(text: 'example@gmail.com');
  final TextEditingController _ssidController = TextEditingController(text: 'MaNo');
  final TextEditingController _passwordController = TextEditingController(text: '11223344');
  final TextEditingController _serialController = TextEditingController(text: 'Serial Number Kamu');
  final TextEditingController _activationController = TextEditingController(text: 'Kode Aktivasi');

  final List<String> _speedOptions = ['LAMBAT', 'SEDANG', 'CEPAT', 'CEPAAT'];
  final Map<String, int> _speedValues = {
    'LAMBAT': 500,
    'SEDANG': 200,
    'CEPAT': 100,
    'CEPAAT': 50,
  };

  @override
  void initState() {
    super.initState();
    _emailController.text = 'example@gmail.com';
    _ssidController.text = 'MaNo';
    _passwordController.text = '11223344';
    _serialController.text = 'Serial Number Kamu';
    _activationController.text = 'Kode Aktivasi';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email Section
            _buildSection(
              title: '# Émail',
              children: [
                _buildTextField(
                  controller: _emailController,
                  hintText: 'example@gmail.com',
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  text: 'UBAH',
                  onPressed: () {
                    _showSnackbar('Email berhasil diubah');
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Welcome Mode Section
            _buildSection(
              title: 'Welcome mode',
              children: [
                _buildSettingSwitch(
                  title: 'Animasi',
                  value: _welcomeModeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _welcomeModeEnabled = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildSettingRow(
                  title: 'Durasi',
                  child: _buildSpeedSelector(),
                ),
                const SizedBox(height: 16),
                _buildSettingRow(
                  title: 'MaNo 06 || Balin.',
                  child: Row(
                    children: [
                      _buildCheckbox(true),
                      const SizedBox(width: 16),
                      _buildCheckbox(false),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildActionButton(
                  text: 'KIRIM',
                  onPressed: () {
                    _showSnackbar('Settings berhasil dikirim');
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Firmware Info Section
            _buildSection(
              title: 'Versi Firmware : -',
              children: [
                _buildInfoRow('Versi Aplikasi', '1.0.6'),
                _buildInfoRow('Device ID', ''),
                _buildInfoRow('Level Lisensi', ''),
                _buildInfoRow('Device Channel', ''),
                const SizedBox(height: 16),
                _buildActionButton(
                  text: 'UBAH',
                  onPressed: () {
                    _showSnackbar('Firmware settings diubah');
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // DEARY Speed Section
            _buildSection(
              title: 'DEARY',
              children: [
                _buildSpeedGrid(),
              ],
            ),

            const SizedBox(height: 24),

            // Ulfi Config Section
            _buildSection(
              title: '# Ulfi Config',
              children: [
                _buildConfigRow('SSID', _ssidController),
                _buildConfigRow('PASSWORD', _passwordController),
                const SizedBox(height: 16),
                _buildActionButton(
                  text: 'UBAH',
                  onPressed: () {
                    _showSnackbar('Config berhasil diubah');
                  },
                ),
                const SizedBox(height: 20),
                _buildSubSection(
                  title: 'KALIBRASI REMOT',
                  buttonText: 'MULAI',
                  onPressed: () {
                    _showSnackbar('Kalibrasi dimulai');
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'MaNo type',
                  style: TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // User Info Section
            _buildSection(
              title: '# 18.57',
              children: [
                _buildSubSection(
                  title: 'USERSI',
                  children: [
                    _buildSerialRow('Serial Number Kamu', 'COPY', 'BUY NOW'),
                    _buildSerialRow('Kode Aktivasi', 'PASTE', 'AKTIVASI'),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSubSection(
                  title: '',
                  children: [
                    _buildActionButton(
                      text: 'RESET PABRIK',
                      onPressed: () {
                        _showSnackbar('Reset pabrik dilakukan');
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      text: 'CHECK UPDATE',
                      onPressed: () {
                        _showSnackbar('Checking for updates...');
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      text: 'UPLOAD FIRMWARE',
                      onPressed: () {
                        _showSnackbar('Upload firmware dimulai');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildActionButton(
                  text: 'HUBUNGI KAMI',
                  onPressed: () {
                    _showSnackbar('Membuka kontak support');
                  },
                  backgroundColor: AppColors.darkGrey,
                  foregroundColor: AppColors.neonGreen,
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.neonGreen,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSubSection({required String title, List<Widget>? children, String? buttonText, Function()? onPressed}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: const TextStyle(
              color: AppColors.pureWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (children != null) ...children,
        if (buttonText != null && onPressed != null) 
          _buildActionButton(text: buttonText, onPressed: onPressed),
      ],
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hintText}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.5)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppColors.pureWhite),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(color: AppColors.pureWhite.withOpacity(0.6)),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required Function() onPressed,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.neonGreen,
          foregroundColor: foregroundColor ?? AppColors.primaryBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingSwitch({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.pureWhite,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.neonGreen,
          activeTrackColor: AppColors.neonGreen.withOpacity(0.5),
        ),
      ],
    );
  }

  Widget _buildSettingRow({required String title, required Widget child}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.pureWhite,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildSpeedSelector() {
    return DropdownButton<String>(
      value: _selectedSpeed,
      dropdownColor: AppColors.darkGrey,
      style: const TextStyle(
        color: AppColors.pureWhite,
        fontSize: 12,
      ),
      underline: Container(
        height: 1,
        color: AppColors.neonGreen,
      ),
      icon: Icon(Icons.arrow_drop_down, color: AppColors.neonGreen, size: 20),
      items: _speedOptions.map((String speed) {
        return DropdownMenuItem<String>(
          value: speed,
          child: Text(
            '$speed (${_speedValues[speed]}ms)',
            style: const TextStyle(
              color: AppColors.pureWhite,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedSpeed = value!;
        });
      },
    );
  }

  Widget _buildCheckbox(bool value) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: value ? AppColors.neonGreen : AppColors.primaryBlack,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.neonGreen),
      ),
      child: value
          ? Icon(Icons.check, size: 16, color: AppColors.primaryBlack)
          : null,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label :',
            style: TextStyle(
              color: AppColors.pureWhite.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.pureWhite,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2,
      ),
      itemCount: _speedOptions.length,
      itemBuilder: (context, index) {
        final speed = _speedOptions[index];
        final isSelected = _selectedSpeed == speed;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedSpeed = speed;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.neonGreen : AppColors.primaryBlack,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.neonGreen),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  speed,
                  style: TextStyle(
                    color: isSelected ? AppColors.primaryBlack : AppColors.pureWhite,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_speedValues[speed]}',
                  style: TextStyle(
                    color: isSelected ? AppColors.primaryBlack : AppColors.pureWhite,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfigRow(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.pureWhite,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildTextField(controller: controller, hintText: ''),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSerialRow(String label, String leftButton, String rightButton) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.pureWhite,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildSmallButton(leftButton, () {
            _showSnackbar('$leftButton: $label');
          }),
          const SizedBox(width: 4),
          _buildSmallButton(rightButton, () {
            _showSnackbar('$rightButton: $label');
          }),
        ],
      ),
    );
  }

  Widget _buildSmallButton(String text, Function() onPressed) {
    return Container(
      height: 25,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.neonGreen,
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.primaryBlack,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.neonGreen,
        content: Text(
          message,
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