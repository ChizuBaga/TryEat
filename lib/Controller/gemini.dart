import 'package:firebase_ai/firebase_ai.dart';


class GeminiService {
  // 1. Initialize the model instance once
  final GenerativeModel _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.0-flash-lite-001',
  );


  Future<String> summarizeComments(String commentsText) async {
    final prompt = 
      "You are a helpful assistant. Summarize the key points and overall sentiment from the following user comments about a product in 1 paragraph. Be concise (max 100 words): $commentsText";

    try {
      final response = await _model.generateContent([
        Content.text(prompt),
      ]);
      return response.text ?? 'No summary generated.';
    } catch (e) {
      // Handle API errors gracefully
      print('Gemini API Error: $e');
      return 'Could not generate summary at this time.';
    }
  }
}