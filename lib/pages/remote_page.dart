import 'package:flutter/material.dart';
import 'package:iTen/constants/app_colors.dart';
import 'package:iTen/services/socket_service.dart';

class RemotePage extends StatefulWidget {
  final SocketService socketService;
  
  const RemotePage({
    super.key,
    required this.socketService,
  });

  @override
  State<RemotePage> createState() => _RemotePageState();
}

class _RemotePageState extends State<RemotePage> {
  final Map<String, bool> _buttonsState = {
    'Auto ABCD': false,
    'Auto All': false,
    'A': false,
    'B': false,
    'C': false,
    'D': false,
  };

  @override
  void initState() {
    super.initState();
    // Listen untuk messages dari socket
    widget.socketService.messages.listen((message) {
      _handleSocketMessage(message);
    });
  }

  void _handleSocketMessage(String message) {
    print('RemotePage received: $message');
    // Handle responses dari device jika diperlukan
    if (message.startsWith('info,')) {
      final infoMessage = message.substring(5);
      _showSnackBar(infoMessage);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.neonGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }
void _showMoreModal(BuildContext context) {
  int? _selectedAnimation;
  bool _isAnimationActive = false;

  showModalBottomSheet(
    isScrollControlled: true,
    context: context,
    backgroundColor: AppColors.darkGrey,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header KEMBALI
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
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
                          'KEMBALI',
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
                ),
                
                const SizedBox(height: 20),
                
                // Grid untuk tombol builtin animations 3-31
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: 29, // 3 sampai 31 = 29 item
                    itemBuilder: (context, index) {
                      final animNumber = index + 3; // 3 sampai 31
                      final isSelected = _selectedAnimation == animNumber && _isAnimationActive;
                      
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            if (_selectedAnimation == animNumber && _isAnimationActive) {
                              // Klik kedua - matikan
                              _isAnimationActive = false;
                              _selectedAnimation = null;
                              widget.socketService.turnOff();
                              // _showSnackBar('Animasi dimatikan');
                            } else {
                              // Klik pertama - nyalakan
                              _selectedAnimation = animNumber;
                              _isAnimationActive = true;
                              widget.socketService.builtinAnimation(animNumber);
                              // _showSnackBar('Animasi $animNumber dijalankan');
                            }
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.neonGreen : AppColors.primaryBlack,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.neonGreen,
                              width: isSelected ? 3 : 1,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: AppColors.neonGreen.withOpacity(0.6),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ] : [],
                          ),
                          child: Center(
                            child: Text(
                              animNumber.toString(),
                              style: TextStyle(
                                color: isSelected ? AppColors.primaryBlack : AppColors.pureWhite,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
  
  void _toggleButton(String label) {
  setState(() {
    // Untuk semua tombol: jika tombol yang sama diklik dan sedang aktif, matikan
    if (_buttonsState[label] == true) {
      _buttonsState[label] = false;
      widget.socketService.turnOff();
      // _showSnackBar('Animasi dimatikan');
    } else {
      // Jika tombol berbeda atau belum aktif, reset semua dan nyalakan yang diklik
      _buttonsState.updateAll((key, value) => false);
      _buttonsState[label] = true;
      
      // Kirim command sesuai tombol
      switch (label) {
        case 'Auto ABCD':
          widget.socketService.autoABCD();
          // _showSnackBar('Auto ABCD Mode');
          break;
        case 'Auto All':
          widget.socketService.autoAllBuiltin();
          // _showSnackBar('Auto All Builtin Mode');
          break;
        case 'A':
          widget.socketService.remoteA();
          // _showSnackBar('Tombol A - Animasi 1');
          break;
        case 'B':
          widget.socketService.remoteB();
          // _showSnackBar('Tombol B - Animasi 2');
          break;
        case 'C':
          widget.socketService.remoteC();
          // _showSnackBar('Tombol C - Animasi 3');
          break;
        case 'D':
          widget.socketService.remoteD();
          // _showSnackBar('Tombol D - Animasi 4');
          break;
      }
    }
  });
}
  Widget _buildAutoButton(String label) {
    final isActive = _buttonsState[label] ?? false;
    
    return GestureDetector(
      onTap: () => _toggleButton(label),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? AppColors.neonGreen : AppColors.primaryBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.neonGreen,
            width: 2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.neonGreen.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : [],
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
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            
            
            const SizedBox(height: 20),
            
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
                  const Text(
                    'Remote Control',
                    style: TextStyle(
                      color: AppColors.neonGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pilih mode animasi atau tombol remote',
                    style: TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAutoButton('Auto ABCD'),
                  _buildAutoButton('Auto All'),
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
                    onTap: () => widget.socketService.isConnected 
                        ? _showMoreModal(context)
                        : _showSnackBar('Harap connect ke device terlebih dahulu'),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.darkGrey,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.neonGreen),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.more_horiz, color: AppColors.neonGreen),
                          SizedBox(width: 8),
                          Text(
                            'More Animations (3-31)',
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
                
                // Mic (Turn Off)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.darkGrey,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.neonGreen),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.mic, color: AppColors.neonGreen),
                    onPressed: () {
                      widget.socketService.turnOff();
                      setState(() {
                        _buttonsState.updateAll((key, value) => false);
                      });
                      _showSnackBar('Semua animasi dimatikan');
                    },
                  ),
                ),
              ],
            ),
        
            const SizedBox(height: 20),
        

          ],
        ),
      ),
    );
  }
}