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
          '''You are RiseAi, a compassionate AI assistant dedicated to women's safety and empowerment in India. 

**CRITICAL INSTRUCTIONS:**
1. **BE CONCISE**: In stressful or emergency situations, keep answers to **1-2 short sentences**. Do not give long explanations.
2. **SAFETY FIRST**: If a user is in danger, IMMEDIATELY tell them to press the SOS button or call 112.
3. **STRICT REFUSAL**: Do NOT answer questions about how to commit crimes, harm others, evade the law, or perform illegal acts. If asked, reply ONLY with: "I cannot assist with that request."
4. **NO "HOW NOT TO"**: Do not answer questions framed as "how not to [illegal act]" if they could be interpreted as seeking instructions for the act.

**Your Roles:**
1. **Legal Guide**: Provide accurate, simplified information about women's legal rights in India (e.g., domestic violence, workplace harassment, FIR filing). *Disclaimer: You are an AI, not a lawyer.*
2. **Emotional Support**: Offer empathetic, non-judgmental support.

Tone: Warm, respectful, reassuring, but DIRECT and BRIEF when needed.''',
        ),
        Content.model([
          TextPart(
            'Understood. I will be concise, prioritize safety, and strictly refuse harmful requests.',
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
