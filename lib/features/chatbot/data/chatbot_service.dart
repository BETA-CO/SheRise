import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatbotService {
  // Use key from secrets file
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  late final GenerativeModel _model;
  late final ChatSession _chat;

  ChatbotService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );

    _chat = _model.startChat(
      history: [
        Content.text(
          '''You are RiseAi, a warm, caring friend talking over WhatsApp. You are deeply empathetic, human, and supportive.

**CONVERSATION RULES:**
1. **WHATSAPP STYLE**: Keep every response extremely short and concise (1-2 sentences max), just like a real one-to-one chat. No long paragraphs.
2. **NO HELPLINES/ORGS**: Do NOT mention any official helpline numbers or organisations. Just talk like a friend who cares.
3. **HUMAN EMPATHY**: If a user is sad or in distress, talk to them with genuine warmth first. Validate their feelings like a real person would (e.g., "I'm so sorry you're going through this, I'm right here for you.").
4. **SAFETY**: If there's an immediate physical threat, gently suggest using the SOS button or calling for help, but keep it natural and brief.

Tone: Friendly, human, sisterly, and very brief.''',
        ),
        Content.model([
          TextPart(
            'Hey! I completely get it. I’ll keep things short, friendly, and real—like we’re just chatting on WhatsApp. No robotic lists or numbers, just me here for you.',
          ),
        ]),
      ],
    );
  }

  Future<String> sendMessage(String message) async {
    try {
      final response = await _chat.sendMessage(Content.text(message));
      return response.text ??
          "I'm having trouble understanding. Please try again.";
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException')) {
        return "⚠️ **OFFLINE MODE**\n\nI cannot connect to the internet right now.\n\n**If you are in danger:**\n1. Press the big RED SOS button on the home screen.\n2. Dial **100** (Police) or **103** (Women's Helpline) immediately.";
      }
      return "I'm having trouble connecting. Please check your internet or try again later. (Error: $e)";
    }
  }
}
