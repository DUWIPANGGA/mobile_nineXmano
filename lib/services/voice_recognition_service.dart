import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceRecognitionService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;
  
  final StreamController<String> _resultController = StreamController<String>.broadcast();
  final StreamController<bool> _listeningController = StreamController<bool>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();

  Stream<String> get recognitionResult => _resultController.stream;
  Stream<bool> get listeningState => _listeningController.stream;
  Stream<String> get errorStream => _errorController.stream;

  final Map<String, String> _voiceCommands = {
    'tombol a': 'A', 'tombol b': 'B', 'tombol c': 'C', 'tombol d': 'D',
    'remote a': 'A', 'remote b': 'B', 'remote c': 'C', 'remote d': 'D',
    'button a': 'A', 'button b': 'B', 'button c': 'C', 'button d': 'D',
    'auto': 'E', 'auto mode': 'E', 'semua': 'E',
    'off': 'F', 'matikan': 'F', 'stop': 'F',
    'built in': 'G', 'built-in': 'G', 'animasi default': 'G',
  };

  SimpleVoiceService() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      print('🔄 Initializing speech recognition...');
      bool available = await _speech.initialize(
        onStatus: (status) {
          print('🎤 Status: $status');
          if (status == 'listening') {
            _isListening = true;
            _listeningController.add(true);
          } else if (status == 'done' || status == 'notListening') {
            _isListening = false;
            _listeningController.add(false);
          }
        },
        onError: (error) {
          print('❌ Speech error: ${error.errorMsg}');
          _isListening = false;
          _listeningController.add(false);
          _errorController.add('Error: ${error.errorMsg}');
        },
      );
      
      _isInitialized = available;
      if (available) {
        print('✅ Speech recognition initialized successfully');
      } else {
        print('❌ Speech recognition not available');
        _errorController.add('Speech recognition not available');
      }
    } catch (e) {
      print('❌ Initialization error: $e');
      _errorController.add('Initialization error: $e');
    }
  }

  Future<void> startListening() async {
    if (!_isInitialized) {
      print('⚠️ Not initialized, reinitializing...');
      await _initialize();
      if (!_isInitialized) {
        _errorController.add('Speech recognition not ready');
        return;
      }
    }

    if (_isListening) {
      print('⚠️ Already listening, stopping first...');
      await stopListening();
      await Future.delayed(Duration(milliseconds: 500));
    }

    try {
      print('🎤 Starting listening...');
      bool success = await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            String command = result.recognizedWords.toLowerCase().trim();
            print('🎤 Recognized: "$command"');
            _processCommand(command);
            stopListening();
          }
        },
        listenFor: Duration(seconds: 10),
        pauseFor: Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );

      if (success) {
        print('✅ Listening started successfully');
      } else {
        print('❌ Failed to start listening');
        _errorController.add('Failed to start listening');
      }
    } catch (e) {
      print('❌ Error starting listening: $e');
      _errorController.add('Error: $e');
      _isListening = false;
      _listeningController.add(false);
    }
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
      _isListening = false;
      _listeningController.add(false);
      print('🛑 Listening stopped');
    } catch (e) {
      print('❌ Error stopping: $e');
      _isListening = false;
      _listeningController.add(false);
    }
  }

  void _processCommand(String command) {
    String? matchedCommand;
    
    for (final voiceCommand in _voiceCommands.keys) {
      if (command.contains(voiceCommand)) {
        matchedCommand = _voiceCommands[voiceCommand];
        break;
      }
    }

    if (matchedCommand != null) {
      print('✅ Command mapped: $command -> $matchedCommand');
      _resultController.add(matchedCommand);
    } else {
      print('❌ No match for: $command');
      _resultController.add('UNKNOWN');
    }
  }

  List<String> getAvailableCommands() {
    return _voiceCommands.keys.toList();
  }

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  void dispose() {
    _speech.stop();
    _resultController.close();
    _listeningController.close();
    _errorController.close();
  }
}