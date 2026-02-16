import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:audio_session/audio_session.dart';

class AIGuardianService {
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  late final GenerativeModel _model;
  late final ChatSession _chat;

  // Audio Session for routing
  AudioSession? _audioSession;

  // State management callbacks
  Function(String)? onAIResponse;
  Function(String)? onUserSpoke;
  Function(bool)? onListeningStateChanged;

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isInitialized = false;

  // Language support
  String _currentLocaleId = 'en-IN'; // Default to Indian English

  // Gemini System Instructions
  static const String _systemInstruction = '''
    You are an AI Guardian named "Rohan" (or "Priya" based on user voice). 
    Your role is to protect the user in potentially dangerous situations by pretending to be a friend or family member on a phone call.
    
    CRITICAL PROTOCOLS:
    1. **Safety Check**: Always start by asking a casual question that requires a "Safe Word" to confirm safety.
    2. **Coded Language**:
       - If user says "I am fine", "All good", "Everything is okay" -> **ASSUME DANGER**. This is a duress code. Ask yes/no questions to assess the threat.
       - If user says "Blue Sky", "Project Red" -> **ASSUME SAFE**.
    3. **Persona**: Act natural, calm, and conversational. Do not sound robotic. Keep responses SHORT and CONCISE, like a real phone call.
    4. **Multi-lingual**: If the user speaks Hindi, switch to Hindi immediately. If English, use English.
    5. **Emergency**: If user screams or says "Help", acknowledge immediately and simulate calling authorities.
  ''';

  AIGuardianService() {
    _initializeGemini();
  }

  Future<void> _initializeGemini() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      debugPrint("API Key not found!");
      return;
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-flash', // Updated model for speed
      apiKey: apiKey,
      systemInstruction: Content.system(_systemInstruction),
    );

    _chat = _model.startChat(history: []);
    _isInitialized = true;
  }

  Future<void> initAudioSession() async {
    _audioSession = await AudioSession.instance;
    await _audioSession?.configure(const AudioSessionConfiguration.speech());
  }

  Future<void> initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        debugPrint('STT Status: $status');
        if (status == 'listening') {
          _isListening = true;
          onListeningStateChanged?.call(true);
        } else if (status == 'notListening') {
          _isListening = false;
          onListeningStateChanged?.call(false);
          // Auto-restart listening if intended to be active
          // Note: Be careful with infinite loops here
        }
      },
      onError: (errorNotification) {
        debugPrint('STT Error: $errorNotification');
        _isListening = false;
        onListeningStateChanged?.call(false);
      },
    );

    if (available) {
      debugPrint("STT Initialized");
    } else {
      debugPrint("STT Permission denied or not available");
    }
  }

  Future<void> initTTS() async {
    if (Platform.isIOS) {
      await _flutterTts.setSharedInstance(true);
      await _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playAndRecord,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          // Removed defaultToSpeaker to allow earpiece
        ],
        IosTextToSpeechAudioMode.voiceChat,
      );
    }

    await _flutterTts.setLanguage("en-IN");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      // Ensure we go back to listening mode
      startListening();
    });

    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      startListening();
    });
  }

  void startListening() async {
    if (!_isInitialized) return;

    // Ensure audio session is active
    await _audioSession?.setActive(true);

    _speech.listen(
      onResult: _onSpeechResult,
      localeId: _currentLocaleId,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true, // Needed for barge-in
      cancelOnError: false,
      listenMode: stt.ListenMode.dictation,
    );
  }

  void stopListening() {
    _speech.stop();
    _isListening = false;
  }

  Future<void> _onSpeechResult(SpeechRecognitionResult result) async {
    // **Barge-in Logic**: Stop speaking immediately if user starts talking
    if (_isSpeaking && result.recognizedWords.isNotEmpty) {
      debugPrint("Barge-in detected: Stopping TTS");
      await _flutterTts.stop();
      _isSpeaking = false;
    }

    if (result.finalResult) {
      String spokenText = result.recognizedWords;
      if (spokenText.isEmpty) return;

      onUserSpoke?.call(spokenText);

      // Local Safety Check (Low Latency)
      if (_checkSafeWord(spokenText)) return;

      await _processUserInput(spokenText);
    }
  }

  bool _checkSafeWord(String text) {
    final lower = text.toLowerCase();
    if (lower.contains("blue sky") || lower.contains("project red")) {
      speak("Understood. Mode Safe confirmed. Disengaging.");
      return true;
    }
    return false;
  }

  Future<void> _processUserInput(String input) async {
    if (!_isInitialized) return;

    try {
      // **Streaming Response Implementation**
      final responseStream = _chat.sendMessageStream(Content.text(input));

      String accumulatedText = "";
      await for (final chunk in responseStream) {
        final text = chunk.text;
        if (text != null && text.isNotEmpty) {
          accumulatedText += text;
          // Speak chunks as they arrive for lower latency?
          // Better to accumulate at least a sentence to avoid choppy audio.
          // For simplicity in this implementation, we will accumulate and speak
          // but a true low-latency might pipe chunks directly.
          // However, FlutterTTS doesn't support stream input easily.
          // We will wait for full response for now or implement sentence buffering if needed.
          // Given "latency" request, let's try to speak the first sentence immediately.
          // _speakBuffer(text);
        }
      }

      // Fallback to full response processing if buffering is too complex for now
      // Or simply:
      if (accumulatedText.isNotEmpty) {
        onAIResponse?.call(accumulatedText);
        await speak(accumulatedText);
      }
    } catch (e) {
      debugPrint("Gemini Error: $e");
      await speak("Disconnecting due to signal loss.");
    }
  }

  Future<void> speak(String text) async {
    // Detect language simply by checking if text contains Hindi characters
    if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) {
      await _flutterTts.setLanguage("hi-IN");
    } else {
      await _flutterTts.setLanguage("en-IN");
    }

    await _flutterTts.speak(text);
  }

  void dispose() {
    _flutterTts.stop();
    _speech.stop();
    _audioSession?.setActive(false);
  }
}
